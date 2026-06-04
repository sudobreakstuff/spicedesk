-- Fix: create_sale function — search_path was blocking internal function calls
DROP FUNCTION IF EXISTS create_sale(UUID, UUID, TEXT, JSONB);

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

    INSERT INTO sales_transactions (
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

        INSERT INTO sale_items (
            id, workspace_id, transaction_id, product_id, product_name,
            quantity, unit_price, line_total
        ) VALUES (
            gen_random_uuid(), p_workspace_id, v_sale_id,
            v_product_id, v_item->>'product_name',
            v_quantity, (v_item->>'unit_price')::NUMERIC, v_line_total
        );

        UPDATE inventory
        SET quantity_on_hand = quantity_on_hand - v_quantity, updated_at = now()
        WHERE workspace_id = p_workspace_id AND product_id = v_product_id;

        INSERT INTO stock_movements (
            id, workspace_id, product_id, quantity_change, movement_type,
            reference_type, reference_id, performed_by
        ) VALUES (
            gen_random_uuid(), p_workspace_id, v_product_id,
            -v_quantity, 'sale', 'sales_transaction', v_sale_id, auth.uid()
        );

        -- Auto-deduct raw materials
        BEGIN
            PERFORM deduct_raw_materials_on_sale(p_workspace_id, v_product_id, v_quantity);
        EXCEPTION WHEN OTHERS THEN
            -- Recipe deduction is optional — don't fail the sale
            RAISE NOTICE 'Raw material deduction skipped: %', SQLERRM;
        END;
    END LOOP;

    RETURN jsonb_build_object(
        'sale_id', v_sale_id,
        'transaction_number', v_transaction_number,
        'total', v_grand_total
    );
END;
$$;
