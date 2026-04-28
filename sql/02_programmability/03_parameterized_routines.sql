DELIMITER $$

DROP PROCEDURE IF EXISTS sp_borrow_equipment $$
CREATE PROCEDURE sp_borrow_equipment(
    IN p_equip_id INT,
    IN p_user_id INT,
    IN p_borrow_date DATE,
    IN p_days INT
)
BEGIN
    DECLARE v_equipment_count INT DEFAULT 0;
    DECLARE v_user_count INT DEFAULT 0;

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

    SELECT COUNT(*)
    INTO v_user_count
    FROM users
    WHERE user_id = p_user_id;

    IF v_user_count = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '用户不存在';
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

    SELECT
        LAST_INSERT_ID() AS new_record_id,
        p_equip_id AS equip_id,
        '借用成功，设备状态已由触发器自动更新' AS message;
END $$

DROP PROCEDURE IF EXISTS sp_return_equipment $$
CREATE PROCEDURE sp_return_equipment(
    IN p_record_id INT,
    IN p_return_date DATE
)
BEGIN
    DECLARE v_not_found INT DEFAULT 0;
    DECLARE v_equip_id INT;
    DECLARE v_borrow_date DATE;
    DECLARE v_actual_return_date DATE;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_not_found = 1;

    IF p_record_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '借用记录编号不能为空';
    END IF;

    IF p_return_date IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '归还日期不能为空';
    END IF;

    SELECT equip_id, borrow_date, actual_return_date
    INTO v_equip_id, v_borrow_date, v_actual_return_date
    FROM borrowrecords
    WHERE record_id = p_record_id;

    IF v_not_found = 1 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '借用记录不存在';
    END IF;

    IF v_actual_return_date IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '该借用记录已经归还，不能重复归还';
    END IF;

    IF p_return_date < v_borrow_date THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '归还日期不能早于借用日期';
    END IF;

    UPDATE borrowrecords
    SET actual_return_date = p_return_date
    WHERE record_id = p_record_id;

    SELECT
        p_record_id AS record_id,
        v_equip_id AS equip_id,
        '归还成功，设备状态已由触发器自动更新' AS message;
END $$

DROP FUNCTION IF EXISTS fn_user_active_borrow_count $$
CREATE FUNCTION fn_user_active_borrow_count(p_user_id INT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_count INT DEFAULT 0;

    SELECT COUNT(*)
    INTO v_count
    FROM borrowrecords
    WHERE user_id = p_user_id
      AND actual_return_date IS NULL;

    RETURN v_count;
END $$

DELIMITER ;
