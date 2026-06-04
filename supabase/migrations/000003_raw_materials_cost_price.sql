-- ============================================================
-- SpiceDesk — Raw Materials & Cost Tracking
-- ============================================================

-- Add product_type to products (raw_material, finished, service)
ALTER TABLE products ADD COLUMN IF NOT EXISTS product_type TEXT DEFAULT 'finished'
  CHECK (product_type IN ('finished', 'raw_material', 'service'));

-- Add unit_of_measure to products and inventory
ALTER TABLE products ADD COLUMN IF NOT EXISTS unit_of_measure TEXT DEFAULT 'unit';
ALTER TABLE inventory ADD COLUMN IF NOT EXISTS unit_of_measure TEXT DEFAULT 'unit';

-- Raw material recipes (bill of materials) — what raw materials go into a finished product
CREATE TABLE IF NOT EXISTS recipes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    finished_product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    raw_material_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    quantity_required NUMERIC(12,4) NOT NULL,
    unit_of_measure TEXT DEFAULT 'unit',
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(workspace_id, finished_product_id, raw_material_id)
);

CREATE INDEX IF NOT EXISTS idx_recipes_workspace ON recipes(workspace_id);
CREATE INDEX IF NOT EXISTS idx_recipes_finished ON recipes(finished_product_id);
CREATE INDEX IF NOT EXISTS idx_recipes_raw ON recipes(raw_material_id);

-- Purchase orders for raw materials
CREATE TABLE IF NOT EXISTS purchase_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    po_number TEXT,
    supplier_id UUID REFERENCES customers(id) ON DELETE SET NULL,
    status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'ordered', 'received', 'cancelled')),
    total_cost NUMERIC(12,2) DEFAULT 0,
    notes TEXT,
    created_by UUID REFERENCES auth.users(id),
    ordered_at TIMESTAMPTZ,
    received_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(workspace_id, po_number)
);

CREATE INDEX IF NOT EXISTS idx_po_workspace ON purchase_orders(workspace_id);

CREATE TABLE IF NOT EXISTS purchase_order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    po_id UUID NOT NULL REFERENCES purchase_orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id),
    quantity NUMERIC(12,2) NOT NULL,
    unit_cost NUMERIC(12,2) NOT NULL,
    line_total NUMERIC(12,2) NOT NULL,
    received_quantity NUMERIC(12,2) DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_po_items_po ON purchase_order_items(po_id);

-- Function: Receive a purchase order (adds to inventory)
CREATE OR REPLACE FUNCTION receive_purchase_order(
    p_po_id UUID,
    p_workspace_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_item RECORD;
    v_total_cost NUMERIC(12,2) := 0;
    v_inv_id UUID;
BEGIN
    -- Update PO status
    UPDATE purchase_orders SET status = 'received', received_at = now()
    WHERE id = p_po_id AND workspace_id = p_workspace_id;

    -- Process each line item
    FOR v_item IN
        SELECT * FROM purchase_order_items
        WHERE po_id = p_po_id AND workspace_id = p_workspace_id
    LOOP
        -- Add received qty
        UPDATE purchase_order_items
        SET received_quantity = v_item.quantity
        WHERE id = v_item.id;

        v_total_cost := v_total_cost + v_item.line_total;

        -- Upsert inventory
        SELECT id INTO v_inv_id FROM inventory
        WHERE workspace_id = p_workspace_id AND product_id = v_item.product_id;

        IF FOUND THEN
            UPDATE inventory
            SET quantity_on_hand = quantity_on_hand + v_item.quantity,
                updated_at = now()
            WHERE id = v_inv_id;
        ELSE
            INSERT INTO inventory (workspace_id, product_id, quantity_on_hand, reorder_point)
            VALUES (p_workspace_id, v_item.product_id, v_item.quantity, 0);
        END IF;

        -- Update product cost price (weighted average)
        UPDATE products
        SET cost_price = CASE
            WHEN cost_price IS NULL OR cost_price = 0 THEN v_item.unit_cost
            ELSE (cost_price + v_item.unit_cost) / 2
            END
        WHERE id = v_item.product_id AND workspace_id = p_workspace_id;

        -- Record stock movement
        INSERT INTO stock_movements (
            workspace_id, product_id, quantity_change, movement_type,
            reference_type, reference_id, performed_by
        ) VALUES (
            p_workspace_id, v_item.product_id, v_item.quantity, 'purchase',
            'purchase_order', p_po_id, auth.uid()
        );
    END LOOP;

    -- Update PO total
    UPDATE purchase_orders SET total_cost = v_total_cost
    WHERE id = p_po_id;

    RETURN jsonb_build_object('status', 'received', 'total_cost', v_total_cost);
END;
$$;

-- Auto-deduct raw materials when a finished product is sold
CREATE OR REPLACE FUNCTION deduct_raw_materials_on_sale(
    p_workspace_id UUID,
    p_product_id UUID,
    p_quantity_sold NUMERIC
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_recipe RECORD;
    v_deduct_qty NUMERIC;
BEGIN
    FOR v_recipe IN
        SELECT * FROM recipes
        WHERE workspace_id = p_workspace_id
          AND finished_product_id = p_product_id
    LOOP
        v_deduct_qty := v_recipe.quantity_required * p_quantity_sold;

        -- Deduct raw material from inventory
        UPDATE inventory
        SET quantity_on_hand = quantity_on_hand - v_deduct_qty,
            updated_at = now()
        WHERE workspace_id = p_workspace_id
          AND product_id = v_recipe.raw_material_id;

        -- Record stock movement for raw material
        INSERT INTO stock_movements (
            workspace_id, product_id, quantity_change, movement_type,
            reference_type, reference_id, notes, performed_by
        ) VALUES (
            p_workspace_id, v_recipe.raw_material_id, -v_deduct_qty, 'sale',
            'raw_material_deduction', gen_random_uuid(),
            'Auto-deducted from sale of finished product', auth.uid()
        );
    END LOOP;
END;
$$;

-- Update create_sale to call raw material deduction
CREATE OR REPLACE FUNCTION create_sale(
    p_workspace_id UUID,
    p_customer_id UUID,
    p_payment_method TEXT,
    p_items JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_sale_id UUID;
    v_transaction_number TEXT;
    v_subtotal NUMERIC(12,2) := 0;
    v_tax_total NUMERIC(12,2) := 0;
    v_grand_total NUMERIC(12,2) := 0;
    v_item JSONB;
    v_line_total NUMERIC(12,2);
    v_product_id UUID;
    v_quantity NUMERIC;
BEGIN
    v_transaction_number := next_transaction_number(p_workspace_id);
    v_sale_id := gen_random_uuid();

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_line_total := (v_item->>'unit_price')::NUMERIC * (v_item->>'quantity')::NUMERIC;
        v_subtotal := v_subtotal + v_line_total;
    END LOOP;

    v_grand_total := v_subtotal + v_tax_total;

    INSERT INTO public.sales_transactions (
        id, workspace_id, transaction_number, customer_id, cashier_id,
        subtotal, tax_total, discount_total, grand_total, payment_method
    ) VALUES (
        v_sale_id, p_workspace_id, v_transaction_number, p_customer_id, auth.uid(),
        v_subtotal, v_tax_total, 0, v_grand_total, p_payment_method
    );

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_product_id := (v_item->>'product_id')::UUID;
        v_quantity := (v_item->>'quantity')::NUMERIC;
        v_line_total := (v_item->>'unit_price')::NUMERIC * v_quantity;

        INSERT INTO public.sale_items (
            id, workspace_id, transaction_id, product_id, product_name,
            quantity, unit_price, line_total
        ) VALUES (
            gen_random_uuid(), p_workspace_id, v_sale_id,
            v_product_id, v_item->>'product_name',
            v_quantity, (v_item->>'unit_price')::NUMERIC, v_line_total
        );

        -- Deduct finished product inventory
        UPDATE public.inventory
        SET quantity_on_hand = quantity_on_hand - v_quantity,
            updated_at = now()
        WHERE workspace_id = p_workspace_id AND product_id = v_product_id;

        -- Record stock movement
        INSERT INTO public.stock_movements (
            id, workspace_id, product_id, quantity_change, movement_type,
            reference_type, reference_id, performed_by
        ) VALUES (
            gen_random_uuid(), p_workspace_id, v_product_id,
            -v_quantity, 'sale', 'sales_transaction', v_sale_id, auth.uid()
        );

        -- Auto-deduct raw materials used in this product
        PERFORM deduct_raw_materials_on_sale(p_workspace_id, v_product_id, v_quantity);
    END LOOP;

    RETURN jsonb_build_object(
        'sale_id', v_sale_id,
        'transaction_number', v_transaction_number,
        'total', v_grand_total
    );
END;
$$;

-- ============================================================
-- RLS for new tables
-- ============================================================
ALTER TABLE recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_order_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "workspace_access" ON recipes
    FOR ALL TO authenticated
    USING (workspace_id IN (SELECT get_user_workspace_ids()))
    WITH CHECK (workspace_id IN (SELECT get_user_workspace_ids()));

CREATE POLICY "workspace_access" ON purchase_orders
    FOR ALL TO authenticated
    USING (workspace_id IN (SELECT get_user_workspace_ids()))
    WITH CHECK (workspace_id IN (SELECT get_user_workspace_ids()));

CREATE POLICY "workspace_access" ON purchase_order_items
    FOR ALL TO authenticated
    USING (workspace_id IN (SELECT get_user_workspace_ids()))
    WITH CHECK (workspace_id IN (SELECT get_user_workspace_ids()));
