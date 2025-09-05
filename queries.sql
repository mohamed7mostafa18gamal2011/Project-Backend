SELECT * FROM customers WHERE created_at >= now() - interval '30 days' ORDER BY created_at DESC;

SELECT product_id, sku, name, stock FROM products WHERE stock <= 10 ORDER BY stock ASC;

SELECT product_id, name, price FROM products ORDER BY price DESC LIMIT 10;

SELECT o.order_id, o.placed_at, o.total, c.first_name, c.last_name, c.email
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
WHERE o.total > 100
ORDER BY o.placed_at DESC LIMIT 20;

SELECT o.order_id, o.total, p.payment_id, p.amount, p.status
FROM orders o
LEFT JOIN payments p ON p.order_id = o.order_id
ORDER BY o.order_id;


SELECT oi.order_item_id, oi.order_id, p.sku, p.name, oi.quantity, oi.unit_price, oi.line_total
FROM order_items oi
JOIN product
