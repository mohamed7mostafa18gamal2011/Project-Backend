TRUNCATE product_price_history, payments, order_items, orders, products, suppliers, categories, addresses, customers RESTART IDENTITY CASCADE;


INSERT INTO customers (first_name, last_name, email, phone) VALUES
('Ahmed','Ibrahim','ahmed.ibrahim@example.com','+201011112223'),
('Mona','Said','mona.said@example.com','+201011112224'),
('Omar','Hassan','omar.hassan@example.com','+201011112225'),
('Sara','Ali','sara.ali@example.com','+201011112226'),
('Tarek','Kamal','tarek.kamal@example.com','+201011112227'),
('Laila','Mostafa','laila.mostafa@example.com','+201011112228'),
('Khaled','Fathy','khaled.fathy@example.com','+201011112229'),
('Dina','Nabil','dina.nabil@example.com','+201011112230'),
('Youssef','Mahmoud','youssef.mahmoud@example.com','+201011112231'),
('Fatma','Adel','fatma.adel@example.com','+201011112232');


INSERT INTO addresses (customer_id, line1, city, state, postal_code, country, is_default) VALUES
(1,'10 Nile St.','Cairo','Cairo','11511','Egypt',TRUE),
(2,'44 Garden City','Cairo','Cairo','11511','Egypt',TRUE),
(3,'7 Al-Mohandiseen','Giza','Giza','12345','Egypt',TRUE),
(4,'2 Downtown','Cairo','Cairo','11511','Egypt',TRUE),
(5,'23 Al-Sawy','Cairo','Cairo','11511','Egypt',TRUE);


INSERT INTO categories (name, description) VALUES
('Electronics','Phones, computers and accessories'),
('Home Appliances','Appliances for home use'),
('Books','Printed and electronic books'),
('Clothing','Men and women clothing'),
('Sports','Sporting goods and equipment');


INSERT INTO suppliers (name, contact_email) VALUES
('Global Samsung Electronics','sales@samsung.example'),
('HomeStuff Ltd.','contact@homestuff.example'),
('BookHub','orders@bookhub.example'),
('Fashioncom','wholesale@fashioncom.example'),
('SportPromax','info@sportpromax.example');

INSERT INTO products (sku, name, description, price, stock, category_id, supplier_id) VALUES
('ELE-001','Smartphone Model A','A midrange smartphone',299.99,50,1,1),
('ELE-002','Wireless Headphones','Noise-cancelling over-ear',129.99,100,1,1),
('ELE-003','USB-C Charger','Fast charging 30W',19.99,200,1,1),
('HOME-001','Blender 600W','Kitchen blender',49.99,40,2,2),
('HOME-002','Vacuum Cleaner X','Bagless vacuum',149.99,25,2,2),
('BOOK-001','Learn Python','Programming book',39.99,80,3,3),
('BOOK-002','Cooking Basics','Recipe book',24.99,60,3,3),
('CLOTH-001','Men T-Shirt','100% cotton',14.99,150,4,4),
('CLOTH-002','Women Jacket','Waterproof jacket',89.99,30,4,4),
('SPORT-001','Football','Size 5 official',29.99,75,5,5),
('SPORT-002','Yoga Mat','Non-slip mat',19.99,120,5,5),
('ELE-004','Laptop 14"','Lightweight laptop',799.99,15,1,1),
('ELE-005','External SSD 1TB','Portable SSD',119.99,80,1,1),
('HOME-003','Air Fryer','4L air fryer',99.99,45,2,2),
('CLOTH-003','Sneakers','Running shoes',69.99,60,4,4),
('ELE-006','Smartwatch S1','Fitness watch',159.99,40,1,1),
('BOOK-003','Machine Learning','Advanced ML text',59.99,30,3,3),
('SPORT-003','Dumbbell Set','Adjustable',89.99,20,5,5),
('ELE-007','Bluetooth Speaker','Portable speaker',49.99,90,1,1),
('HOME-004','Electric Kettle','1.7L kettle',29.99,110,2,2);


INSERT INTO product_price_history (product_id, old_price, new_price) VALUES
(1,319.99,299.99),(12,899.99,799.99);


DO $$
DECLARE
  cid INTEGER := 1;
  i INTEGER := 1;
  p RECORD;
  order_total NUMERIC(12,2);
BEGIN
  FOR i IN 1..30 LOOP
    cid := ((i-1) % 10) + 1;

    INSERT INTO orders (customer_id, address_id, status, total)
    VALUES (cid, (SELECT address_id FROM addresses WHERE customer_id = cid LIMIT 1), 'pending', 0)
    RETURNING order_id INTO p;

    order_total := 0;


    PERFORM setseed(extract(epoch from now()));
    FOR j IN 1..(1 + (i % 3)) LOOP

      DECLARE prod_id INTEGER := (1 + ((i * j * 7) % 20));
      DECLARE unit_p NUMERIC := (SELECT price FROM products WHERE product_id = prod_id);
      DECLARE qty INTEGER := 1 + ((i + j) % 3);
      DECLARE line_total NUMERIC := unit_p * qty;
      INSERT INTO order_items (order_id, product_id, unit_price, quantity, line_total)
      VALUES (p.order_id, prod_id, unit_p, qty, line_total);
      order_total := order_total + line_total;
      -- reduce stock
      UPDATE products SET stock = GREATEST(stock - qty, 0) WHERE product_id = prod_id;
    END LOOP;


    UPDATE orders SET total = order_total,
                 status = CASE WHEN (i % 7) IN (0,1) THEN 'paid' WHEN (i%7)=2 THEN 'shipped' WHEN (i%7)=3 THEN 'completed' WHEN (i%7)=4 THEN 'cancelled' ELSE 'pending' END
    WHERE order_id = p.order_id;

    IF (i % 7) IN (0,1,2,3) THEN
      INSERT INTO payments (order_id, amount, method, status, reference)
      VALUES (p.order_id, order_total, 'card', 'completed', 'PAY' || p.order_id || to_char(now(),'YYMMDD'));
    ELSE
      INSERT INTO payments (order_id, amount, method, status, reference)
      VALUES (p.order_id, 0, 'card', 'pending', NULL);
    END IF;
  END LOOP;
END;$$;
