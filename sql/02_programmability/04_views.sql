CREATE OR REPLACE VIEW v_equipment_detail AS
SELECT
    e.equip_id,
    e.equip_name,
    e.category_id,
    c.category_name,
    e.room_id,
    r.room_name,
    r.location,
    r.admin_name,
    e.status,
    e.price,
    e.purchase_date
FROM equipments e
JOIN categories c ON e.category_id = c.category_id
JOIN labrooms r ON e.room_id = r.room_id;

CREATE OR REPLACE VIEW v_borrowrecord_detail AS
SELECT
    b.record_id,
    b.equip_id,
    e.equip_name,
    e.status AS equipment_status,
    b.user_id,
    u.user_name,
    u.role,
    u.contact,
    b.borrow_date,
    b.plan_return_date,
    b.actual_return_date,
    CASE
        WHEN b.actual_return_date IS NULL
             AND b.plan_return_date < CURRENT_DATE() THEN 'Overdue'
        WHEN b.actual_return_date IS NULL THEN 'Active'
        ELSE 'Returned'
    END AS record_status
FROM borrowrecords b
JOIN equipments e ON b.equip_id = e.equip_id
JOIN users u ON b.user_id = u.user_id;

SELECT *
FROM v_equipment_detail
LIMIT 10;

SELECT *
FROM v_borrowrecord_detail
ORDER BY record_id DESC
LIMIT 10;
