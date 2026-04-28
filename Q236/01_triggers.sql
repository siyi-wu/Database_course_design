DELIMITER $$

DROP TRIGGER IF EXISTS trg_borrowrecords_before_insert $$
CREATE TRIGGER trg_borrowrecords_before_insert
BEFORE INSERT ON borrowrecords
FOR EACH ROW
BEGIN
    DECLARE v_status VARCHAR(20);
    DECLARE v_active_count INT DEFAULT 0;

    IF NEW.plan_return_date < NEW.borrow_date THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '计划归还日期不能早于借用日期';
    END IF;

    IF NEW.actual_return_date IS NOT NULL
       AND NEW.actual_return_date < NEW.borrow_date THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '实际归还日期不能早于借用日期';
    END IF;

    SELECT status
    INTO v_status
    FROM equipments
    WHERE equip_id = NEW.equip_id;

    IF v_status IN ('Maintenance', 'Scrapped') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '维修或报废设备不能借出';
    END IF;

    IF NEW.actual_return_date IS NULL THEN
        SELECT COUNT(*)
        INTO v_active_count
        FROM borrowrecords
        WHERE equip_id = NEW.equip_id
          AND actual_return_date IS NULL;

        IF v_active_count > 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = '该设备存在未归还记录，不能重复借出';
        END IF;
    END IF;
END $$

DROP TRIGGER IF EXISTS trg_borrowrecords_after_insert $$
CREATE TRIGGER trg_borrowrecords_after_insert
AFTER INSERT ON borrowrecords
FOR EACH ROW
BEGIN
    IF NEW.actual_return_date IS NULL THEN
        UPDATE equipments
        SET status = 'Borrowed'
        WHERE equip_id = NEW.equip_id
          AND status NOT IN ('Maintenance', 'Scrapped');
    END IF;
END $$

DROP TRIGGER IF EXISTS trg_borrowrecords_after_update $$
CREATE TRIGGER trg_borrowrecords_after_update
AFTER UPDATE ON borrowrecords
FOR EACH ROW
BEGIN
    DECLARE v_active_count INT DEFAULT 0;

    IF OLD.actual_return_date IS NULL
       AND NEW.actual_return_date IS NOT NULL THEN
        SELECT COUNT(*)
        INTO v_active_count
        FROM borrowrecords
        WHERE equip_id = NEW.equip_id
          AND actual_return_date IS NULL;

        IF v_active_count = 0 THEN
            UPDATE equipments
            SET status = 'Available'
            WHERE equip_id = NEW.equip_id
              AND status = 'Borrowed';
        END IF;
    END IF;
END $$

DELIMITER ;
