EXPLAIN FORMAT=TREE
SELECT equip_id, equip_name, status
FROM equipments
WHERE category_id = 3
  AND status = 'Available';

EXPLAIN FORMAT=TREE
SELECT record_id, user_id, equip_id, borrow_date
FROM borrowrecords
WHERE user_id = 42
ORDER BY borrow_date DESC
LIMIT 10;

CREATE INDEX idx_equipments_category_status
ON equipments (category_id, status);

CREATE INDEX idx_borrowrecords_user_borrow_date
ON borrowrecords (user_id, borrow_date DESC);

CREATE INDEX idx_borrowrecords_equip_active
ON borrowrecords (equip_id, actual_return_date, plan_return_date);

EXPLAIN FORMAT=TREE
SELECT equip_id, equip_name, status
FROM equipments
WHERE category_id = 3
  AND status = 'Available';

EXPLAIN FORMAT=TREE
SELECT record_id, user_id, equip_id, borrow_date
FROM borrowrecords
WHERE user_id = 42
ORDER BY borrow_date DESC
LIMIT 10;
