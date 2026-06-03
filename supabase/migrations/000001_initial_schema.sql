-- ============================================================
-- SpiceDesk — Database Schema
-- Made by Shahid Singh
-- ============================================================

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- WORKSPACES & MEMBERSHIP
-- ============================================================

CREATE TABLE workspaces (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    slug TEXT UNIQUE,
    invite_code TEXT UNIQUE DEFAULT encode(gen_random_bytes(6), 'hex'),
    logo_url TEXT,
    settings JSONB DEFAULT '{}',
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE workspace_members (
    workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'manager', 'cashier', 'member')),
    joined_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (workspace_id, user_id)
);

-- ============================================================
-- PRODUCTS & CATEGORIES
-- ============================================================

CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    color TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    sku TEXT,
    barcode TEXT,
    description TEXT,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    unit_price NUMERIC(12,2) NOT NULL DEFAULT 0,
    cost_price NUMERIC(12,2) DEFAULT 0,
    tax_rate NUMERIC(5,2) DEFAULT 0,
    image_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(workspace_id, sku)
);

-- ============================================================
-- INVENTORY
-- ============================================================

CREATE TABLE inventory (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    quantity_on_hand NUMERIC(12,2) NOT NULL DEFAULT 0,
    reorder_point NUMERIC(12,2) DEFAULT 10,
    location TEXT DEFAULT 'Main',
    last_counted_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(workspace_id, product_id)
);

CREATE TABLE stock_movements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    quantity_change NUMERIC(12,2) NOT NULL,
    movement_type TEXT NOT NULL CHECK (movement_type IN ('sale', 'purchase', 'adjustment', 'return', 'initial')),
    reference_type TEXT,
    reference_id UUID,
    notes TEXT,
    performed_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- CUSTOMERS
-- ============================================================

CREATE TABLE customers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    address JSONB,
    notes TEXT,
    loyalty_points INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- SALES TRANSACTIONS
-- ============================================================

CREATE TABLE sales_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    transaction_number TEXT,
    customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
    cashier_id UUID REFERENCES auth.users(id),
    subtotal NUMERIC(12,2) NOT NULL DEFAULT 0,
    tax_total NUMERIC(12,2) NOT NULL DEFAULT 0,
    discount_total NUMERIC(12,2) NOT NULL DEFAULT 0,
    grand_total NUMERIC(12,2) NOT NULL DEFAULT 0,
    payment_method TEXT CHECK (payment_method IN ('cash', 'card', 'mobile', 'credit')),
    payment_status TEXT DEFAULT 'completed' CHECK (payment_status IN ('completed', 'refunded', 'voided')),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE sale_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    transaction_id UUID NOT NULL REFERENCES sales_transactions(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    product_name TEXT NOT NULL,
    quantity NUMERIC(12,2) NOT NULL,
    unit_price NUMERIC(12,2) NOT NULL,
    tax_rate NUMERIC(5,2) DEFAULT 0,
    line_total NUMERIC(12,2) NOT NULL,
    discount NUMERIC(12,2) DEFAULT 0
);

-- ============================================================
-- INVOICES & QUOTES (for future use)
-- ============================================================

CREATE TABLE invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    invoice_number TEXT NOT NULL,
    transaction_id UUID REFERENCES sales_transactions(id),
    customer_id UUID REFERENCES customers(id),
    issue_date DATE DEFAULT CURRENT_DATE,
    due_date DATE,
    status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'sent', 'paid', 'overdue', 'cancelled')),
    subtotal NUMERIC(12,2),
    tax_total NUMERIC(12,2),
    total NUMERIC(12,2),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(workspace_id, invoice_number)
);

-- ============================================================
-- MARKETING (for future use)
-- ============================================================

CREATE TABLE marketing_campaigns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    platform TEXT,
    scheduled_at TIMESTAMPTZ,
    status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'scheduled', 'published', 'cancelled')),
    content JSONB DEFAULT '{}',
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_workspace_members_user ON workspace_members(user_id);
CREATE INDEX idx_workspace_members_workspace ON workspace_members(workspace_id);

CREATE INDEX idx_products_workspace ON products(workspace_id);
CREATE INDEX idx_products_barcode ON products(workspace_id, barcode);
CREATE INDEX idx_products_category ON products(workspace_id, category_id);

CREATE INDEX idx_inventory_workspace ON inventory(workspace_id);
CREATE INDEX idx_inventory_product ON inventory(product_id);

CREATE INDEX idx_stock_movements_workspace ON stock_movements(workspace_id);
CREATE INDEX idx_stock_movements_product ON stock_movements(product_id);
CREATE INDEX idx_stock_movements_date ON stock_movements(workspace_id, created_at DESC);

CREATE INDEX idx_customers_workspace ON customers(workspace_id);
CREATE INDEX idx_customers_phone ON customers(workspace_id, phone);

CREATE INDEX idx_sales_workspace ON sales_transactions(workspace_id);
CREATE INDEX idx_sales_date ON sales_transactions(workspace_id, created_at DESC);
CREATE INDEX idx_sales_customer ON sales_transactions(workspace_id, customer_id);
CREATE INDEX idx_sales_cashier ON sales_transactions(workspace_id, cashier_id);

CREATE INDEX idx_sale_items_transaction ON sale_items(transaction_id);
CREATE INDEX idx_sale_items_product ON sale_items(product_id);

CREATE INDEX idx_invoices_workspace ON invoices(workspace_id);
CREATE INDEX idx_invoices_customer ON invoices(workspace_id, customer_id);

CREATE INDEX idx_marketing_workspace ON marketing_campaigns(workspace_id);

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================

-- Get workspace IDs for the current user (used in RLS)
CREATE OR REPLACE FUNCTION get_user_workspace_ids()
RETURNS SETOF UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
    SELECT workspace_id FROM public.workspace_members WHERE user_id = auth.uid();
$$;

-- Auto-generate sequential transaction numbers per workspace
CREATE TABLE transaction_counters (
    workspace_id UUID PRIMARY KEY REFERENCES workspaces(id) ON DELETE CASCADE,
    last_number BIGINT NOT NULL DEFAULT 0
);

CREATE OR REPLACE FUNCTION next_transaction_number(p_workspace_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    next_num BIGINT;
BEGIN
    INSERT INTO transaction_counters (workspace_id, last_number)
    VALUES (p_workspace_id, 1)
    ON CONFLICT (workspace_id) DO UPDATE
    SET last_number = transaction_counters.last_number + 1
    RETURNING last_number INTO next_num;
    RETURN 'TXN-' || LPAD(next_num::TEXT, 6, '0');
END;
$$;

-- Atomic sale creation (inserts transaction, items, and updates inventory)
CREATE OR REPLACE FUNCTION create_sale(
    p_workspace_id UUID,
    p_customer_id UUID,
    p_payment_method TEXT,
    p_items JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_sale_id UUID;
    v_transaction_number TEXT;
    v_subtotal NUMERIC(12,2) := 0;
    v_tax_total NUMERIC(12,2) := 0;
    v_grand_total NUMERIC(12,2) := 0;
    v_item JSONB;
    v_line_total NUMERIC(12,2);
    v_product_record RECORD;
BEGIN
    -- Generate transaction number
    v_transaction_number := next_transaction_number(p_workspace_id);
    v_sale_id := uuid_generate_v4();

    -- Calculate totals from items
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_line_total := (v_item->>'unit_price')::NUMERIC * (v_item->>'quantity')::NUMERIC;
        v_subtotal := v_subtotal + v_line_total;
    END LOOP;

    v_grand_total := v_subtotal + v_tax_total;

    -- Insert sale header
    INSERT INTO sales_transactions (
        id, workspace_id, transaction_number, customer_id, cashier_id,
        subtotal, tax_total, discount_total, grand_total, payment_method
    ) VALUES (
        v_sale_id, p_workspace_id, v_transaction_number, p_customer_id, auth.uid(),
        v_subtotal, v_tax_total, 0, v_grand_total, p_payment_method
    );

    -- Insert line items and update inventory
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_line_total := (v_item->>'unit_price')::NUMERIC * (v_item->>'quantity')::NUMERIC;

        INSERT INTO sale_items (
            id, workspace_id, transaction_id, product_id, product_name,
            quantity, unit_price, line_total
        ) VALUES (
            uuid_generate_v4(), p_workspace_id, v_sale_id,
            (v_item->>'product_id')::UUID,
            v_item->>'product_name',
            (v_item->>'quantity')::NUMERIC,
            (v_item->>'unit_price')::NUMERIC,
            v_line_total
        );

        -- Update inventory
        UPDATE inventory
        SET quantity_on_hand = quantity_on_hand - (v_item->>'quantity')::NUMERIC,
            updated_at = now()
        WHERE workspace_id = p_workspace_id
          AND product_id = (v_item->>'product_id')::UUID;

        -- Record stock movement
        INSERT INTO stock_movements (
            id, workspace_id, product_id, quantity_change, movement_type,
            reference_type, reference_id, performed_by
        ) VALUES (
            uuid_generate_v4(), p_workspace_id, (v_item->>'product_id')::UUID,
            -(v_item->>'quantity')::NUMERIC, 'sale',
            'sales_transaction', v_sale_id, auth.uid()
        );
    END LOOP;

    RETURN jsonb_build_object(
        'sale_id', v_sale_id,
        'transaction_number', v_transaction_number,
        'total', v_grand_total
    );
END;
$$;

-- ============================================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================================

ALTER TABLE workspaces ENABLE ROW LEVEL SECURITY;
ALTER TABLE workspace_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE sale_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketing_campaigns ENABLE ROW LEVEL SECURITY;

ALTER TABLE transaction_counters ENABLE ROW LEVEL SECURITY;

-- transaction_counters is only accessed via the SECURITY DEFINER function
-- No direct access for authenticated or anon users
CREATE POLICY "function_only" ON transaction_counters
    FOR ALL TO authenticated
    USING (false);

-- Workspace members can view their workspaces
CREATE POLICY "members_view" ON workspaces
    FOR SELECT TO authenticated
    USING (id IN (SELECT get_user_workspace_ids()));

-- Workspace members can view memberships
CREATE POLICY "members_view_members" ON workspace_members
    FOR SELECT TO authenticated
    USING (workspace_id IN (SELECT get_user_workspace_ids()));

-- Owners can insert members
CREATE POLICY "owners_insert_members" ON workspace_members
    FOR INSERT TO authenticated
    WITH CHECK (
        workspace_id IN (
            SELECT workspace_id FROM workspace_members
            WHERE user_id = auth.uid() AND role = 'owner'
        )
    );

-- RLS for all workspace-scoped tables
CREATE POLICY "workspace_access" ON categories
    FOR ALL TO authenticated
    USING (workspace_id IN (SELECT get_user_workspace_ids()))
    WITH CHECK (workspace_id IN (SELECT get_user_workspace_ids()));

CREATE POLICY "workspace_access" ON products
    FOR ALL TO authenticated
    USING (workspace_id IN (SELECT get_user_workspace_ids()))
    WITH CHECK (workspace_id IN (SELECT get_user_workspace_ids()));

CREATE POLICY "workspace_access" ON inventory
    FOR ALL TO authenticated
    USING (workspace_id IN (SELECT get_user_workspace_ids()))
    WITH CHECK (workspace_id IN (SELECT get_user_workspace_ids()));

CREATE POLICY "workspace_access" ON stock_movements
    FOR ALL TO authenticated
    USING (workspace_id IN (SELECT get_user_workspace_ids()))
    WITH CHECK (workspace_id IN (SELECT get_user_workspace_ids()));

CREATE POLICY "workspace_access" ON customers
    FOR ALL TO authenticated
    USING (workspace_id IN (SELECT get_user_workspace_ids()))
    WITH CHECK (workspace_id IN (SELECT get_user_workspace_ids()));

CREATE POLICY "workspace_access" ON sales_transactions
    FOR ALL TO authenticated
    USING (workspace_id IN (SELECT get_user_workspace_ids()))
    WITH CHECK (workspace_id IN (SELECT get_user_workspace_ids()));

CREATE POLICY "workspace_access" ON sale_items
    FOR ALL TO authenticated
    USING (workspace_id IN (SELECT get_user_workspace_ids()))
    WITH CHECK (workspace_id IN (SELECT get_user_workspace_ids()));

CREATE POLICY "workspace_access" ON invoices
    FOR ALL TO authenticated
    USING (workspace_id IN (SELECT get_user_workspace_ids()))
    WITH CHECK (workspace_id IN (SELECT get_user_workspace_ids()));

CREATE POLICY "workspace_access" ON marketing_campaigns
    FOR ALL TO authenticated
    USING (workspace_id IN (SELECT get_user_workspace_ids()))
    WITH CHECK (workspace_id IN (SELECT get_user_workspace_ids()));

-- ============================================================
-- REALTIME (only for sales and inventory tables)
-- ============================================================
ALTER PUBLICATION supabase_realtime ADD TABLE sales_transactions;
ALTER PUBLICATION supabase_realtime ADD TABLE sale_items;
ALTER PUBLICATION supabase_realtime ADD TABLE inventory;
ALTER PUBLICATION supabase_realtime ADD TABLE products;

-- ============================================================
-- PROFILE TRIGGER (auto-create profile on signup)
-- ============================================================

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.workspaces (id, name, created_by)
    VALUES (uuid_generate_v4(), NEW.raw_user_meta_data->>'name' || '''s Workspace', NEW.id);
    RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_user();
