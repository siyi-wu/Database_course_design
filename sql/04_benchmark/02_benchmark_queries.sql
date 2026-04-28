EXPLAIN FORMAT=TREE
SELECT SQL_NO_CACHE equip_id, equip_name, status
FROM benchmark_equipments
WHERE category_id = 3
  AND status = 'Available';

EXPLAIN ANALYZE
SELECT SQL_NO_CACHE equip_id, equip_name, status
FROM benchmark_equipments
WHERE category_id = 3
  AND status = 'Available';

EXPLAIN FORMAT=TREE
SELECT SQL_NO_CACHE record_id, user_id, equip_id, borrow_date
FROM benchmark_borrowrecords
WHERE user_id = 42
ORDER BY borrow_date DESC
LIMIT 10;

EXPLAIN ANALYZE
SELECT SQL_NO_CACHE record_id, user_id, equip_id, borrow_date
FROM benchmark_borrowrecords
WHERE user_id = 42
ORDER BY borrow_date DESC
LIMIT 10;

CREATE INDEX idx_bm_equipments_category_status
ON benchmark_equipments (category_id, status);

CREATE INDEX idx_bm_borrowrecords_user_borrow_date
ON benchmark_borrowrecords (user_id, borrow_date DESC);

EXPLAIN FORMAT=TREE
SELECT SQL_NO_CACHE equip_id, equip_name, status
FROM benchmark_equipments
WHERE category_id = 3
  AND status = 'Available';

EXPLAIN ANALYZE
SELECT SQL_NO_CACHE equip_id, equip_name, status
FROM benchmark_equipments
WHERE category_id = 3
  AND status = 'Available';

EXPLAIN FORMAT=TREE
SELECT SQL_NO_CACHE record_id, user_id, equip_id, borrow_date
FROM benchmark_borrowrecords
WHERE user_id = 42
ORDER BY borrow_date DESC
LIMIT 10;

EXPLAIN ANALYZE
SELECT SQL_NO_CACHE record_id, user_id, equip_id, borrow_date
FROM benchmark_borrowrecords
WHERE user_id = 42
ORDER BY borrow_date DESC
LIMIT 10;
