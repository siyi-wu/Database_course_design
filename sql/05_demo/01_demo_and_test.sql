SET @demo_user_id := (
    SELECT user_id
    FROM users
    ORDER BY user_id
    LIMIT 1
);

SET @demo_equip_id := (
    SELECT e.equip_id
    FROM equipments AS e
    WHERE e.status = 'Available'
      AND NOT EXISTS (
          SELECT 1
          FROM borrowrecords AS br
          WHERE br.equip_id = e.equip_id
            AND br.actual_return_date IS NULL
      )
    ORDER BY e.equip_id
    LIMIT 1
);

SELECT
    @demo_user_id AS demo_user_id,
    @demo_equip_id AS demo_equip_id,
    fn_user_active_borrow_count(@demo_user_id) AS active_count_before;

CALL sp_borrow_equipment(@demo_equip_id, @demo_user_id, CURRENT_DATE(), 7);

SET @demo_record_id := LAST_INSERT_ID();

SELECT
    br.record_id,
    br.equip_id,
    br.user_id,
    br.borrow_date,
    br.plan_return_date,
    br.actual_return_date,
    e.status AS equipment_status_after_borrow,
    fn_user_active_borrow_count(@demo_user_id) AS active_count_after_borrow
FROM borrowrecords AS br
JOIN equipments AS e ON e.equip_id = br.equip_id
WHERE br.record_id = @demo_record_id;

CALL sp_return_equipment(@demo_record_id, CURRENT_DATE());

SELECT
    br.record_id,
    br.equip_id,
    br.user_id,
    br.borrow_date,
    br.plan_return_date,
    br.actual_return_date,
    e.status AS equipment_status_after_return,
    fn_user_active_borrow_count(@demo_user_id) AS active_count_after_return
FROM borrowrecords AS br
JOIN equipments AS e ON e.equip_id = br.equip_id
WHERE br.record_id = @demo_record_id;

SHOW TRIGGERS WHERE `Table` = 'borrowrecords';

SHOW PROCEDURE STATUS
WHERE Db = DATABASE()
  AND Name IN ('sp_borrow_equipment', 'sp_return_equipment');

SHOW FUNCTION STATUS
WHERE Db = DATABASE()
  AND Name = 'fn_user_active_borrow_count';
