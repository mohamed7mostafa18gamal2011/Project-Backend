CREATE VIEW detailed_order_summary AS
SELECT o.order_id,
       o.placed_at,
       o.status,
       o.total,
       c.customer_id,
       c.first_name,
       c.last_name,
       c.email,
       COUNT(oi.order_item_id) AS items_count,
       SUM(oi.line_total) AS items_total,
       MAX(p.processed_at) FILTER (WHERE p.status = 'completed') AS payment_completed_at,
       BOOL_OR(p.status = 'completed') AS paid_flag
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
LEFT JOIN order_items oi ON oi.order_id = o.order_id
LEFT JOIN payments p ON p.order_id = o.order_id
GROUP BY o.order_id, o.placed_at, o.status, o.total, c.customer_id, c.first_name, c.last_name, c.email;

CREATE VIEW product_sales_aggregate AS
SELECT p.product_id, p.sku, p.name,
       COALESCE(SUM(oi.quantity),0) AS total_quantity_sold,
       COALESCE(SUM(oi.line_total),0) AS total_revenue
FROM products p
LEFT JOIN order_items oi ON oi.product_id = p.product_id
GROUP BY p.product_id, p.sku, p.name;
