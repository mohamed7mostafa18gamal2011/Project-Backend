CREATE OR REPLACE FUNCTION place_order(p_customer_id INTEGER, p_address_id INTEGER, p_items JSON)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_order_id INTEGER;
  v_total NUMERIC(12,2) := 0;
  v_item JSON;
  v_product_id INTEGER;
  v_qty INTEGER;
  v_price NUMERIC(10,2);
BEGIN
  PERFORM pg_advisory_xact_lock(1); 
  INSERT INTO orders (customer_id, address_id, status, total) VALUES (p_customer_id, p_address_id, 'pending', 0) RETURNING order_id INTO v_order_id;

  FOR v_item IN SELECT * FROM json_array_elements(p_items) LOOP
    v_product_id := (v_item->>'product_id')::INTEGER;
    v_qty := (v_item->>'quantity')::INTEGER;
    SELECT price INTO v_price FROM products WHERE product_id = v_product_id FOR UPDATE;
    IF v_price IS NULL THEN
      RAISE EXCEPTION 'Product % not found', v_product_id;
    END IF;

    INSERT INTO order_items (order_id, product_id, unit_price, quantity, line_total)
    VALUES (v_order_id, v_product_id, v_price, v_qty, v_price * v_qty);

    UPDATE products SET stock = stock - v_qty WHERE product_id = v_product_id;

    v_total := v_total + (v_price * v_qty);
  END LOOP;

  UPDATE orders SET total = v_total WHERE order_id = v_order_id;
  RETURN v_order_id;
END;$$;

CREATE OR REPLACE FUNCTION trg_record_price_change() RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND NEW.price IS DISTINCT FROM OLD.price THEN
    INSERT INTO product_price_history (product_id, old_price, new_price, changed_at)
    VALUES (OLD.product_id, OLD.price, NEW.price, now());
  END IF;
  RETURN NEW;
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER product_price_change AFTER UPDATE ON products
FOR EACH ROW EXECUTE FUNCTION trg_record_price_change();
