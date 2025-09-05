-- Define necessary indexes and explain why

-- 1. Customers email is unique; keep unique index for fast lookup by email
CREATE UNIQUE INDEX idx_customers_email ON customers(email);
-- Reason: login / lookup by email is common and needs to be unique and fast.

-- 2. Products: index on sku and category
CREATE UNIQUE INDEX idx_products_sku ON products(sku);
CREATE INDEX idx_products_category ON products(category_id);
-- Reason: frequent product lookups by SKU and category filters.

-- 3. Orders: index by customer and placed_at for recent orders per customer
CREATE INDEX idx_orders_customer_placedat ON orders(customer_id, placed_at DESC);
-- Reason: used to fetch order history quickly.

-- 4. Payments: index by order_id and status
CREATE INDEX idx_payments_order_status ON payments(order_id, status);
-- Reason: to quickly find payments for an order and their status.

-- 5. Order items: index by product_id for sales aggregation
CREATE INDEX idx_orderitems_product ON order_items(product_id);
-- Reason: aggregation queries (sales per product) will benefit.

-- 6. Addresses: index by customer
CREATE INDEX idx_addresses_customer ON addresses(customer_id);

-- 7. Products: GIN index on name for fast ILIKE search (text search)
CREATE INDEX idx_products_name_trgm ON products USING gin (name gin_trgm_ops);
-- Note: requires pg_trgm extension; helps ILIKE '%term%'.

-- Comments: Consider partial indexes for active suppliers or frequently queried statuses
-- Example partial index: paid orders
CREATE INDEX idx_orders_paid ON orders(placed_at) WHERE status IN ('paid','shipped','completed');
