DELIMITER $$

DROP PROCEDURE IF EXISTS sp_borrow_equipment_tx $$
CREATE PROCEDURE sp_borrow_equipment_tx(
    IN p_equip_id INT,
    IN p_user_id INT,
    IN p_borrow_date DATE,
    IN p_days INT
)
BEGIN
    DECLARE v_equipment_count INT DEFAULT 0;
    DECLARE v_status VARCHAR(20);
    DECLARE v_user_count INT DEFAULT 0;
    DECLARE v_active_count INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_equip_id IS NULL OR p_user_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '设备编号和用户编号不能为空';
    END IF;

    IF p_borrow_date IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '借用日期不能为空';
    END IF;

    IF p_days IS NULL OR p_days <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '借用天数必须为正数';
    END IF;

    SELECT COUNT(*)
    INTO v_equipment_count
    FROM equipments
    WHERE equip_id = p_equip_id;

    IF v_equipment_count = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '设备不存在';
    END IF;

    START TRANSACTION;

    SELECT status
    INTO v_status
    FROM equipments
    WHERE equip_id = p_equip_id
    FOR UPDATE;

    SELECT COUNT(*)
    INTO v_user_count
    FROM users
    WHERE user_id = p_user_id;

    IF v_user_count = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '用户不存在';
    END IF;

    IF v_status IN ('Maintenance', 'Scrapped') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '维修或报废设备不能借出';
    END IF;

    SELECT COUNT(*)
    INTO v_active_count
    FROM borrowrecords
    WHERE equip_id = p_equip_id
      AND actual_return_date IS NULL;

    IF v_active_count > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '该设备存在未归还记录，不能重复借出';
    END IF;

    INSERT INTO borrowrecords (
        equip_id,
        user_id,
        borrow_date,
        plan_return_date,
        actual_return_date
    )
    VALUES (
        p_equip_id,
        p_user_id,
        p_borrow_date,
        DATE_ADD(p_borrow_date, INTERVAL p_days DAY),
        NULL
    );

    COMMIT;

    SELECT
        LAST_INSERT_ID() AS new_record_id,
        p_equip_id AS equip_id,
        '事务借用成功，设备状态已由触发器自动更新' AS message;
END $$

DELIMITER ;

-- 演示用法：
-- CALL sp_borrow_equipment_tx(设备编号, 用户编号, CURRENT_DATE(), 7);
