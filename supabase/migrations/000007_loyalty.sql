CREATE OR REPLACE FUNCTION increment_loyalty(p_customer_id UUID)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE customers SET loyalty_points = loyalty_points + 1 WHERE id = p_customer_id;
END; $$;
