DELIMITER $$

DROP PROCEDURE IF EXISTS sp_sync_equipment_status $$
CREATE PROCEDURE sp_sync_equipment_status()
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE v_equip_id INT;
    DECLARE v_status VARCHAR(20);
    DECLARE v_has_active INT DEFAULT 0;

    DECLARE equip_cursor CURSOR FOR
        SELECT equip_id, status FROM tmp_equipment_snapshot;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    DROP TEMPORARY TABLE IF EXISTS tmp_equipment_snapshot;
    CREATE TEMPORARY TABLE tmp_equipment_snapshot AS
    SELECT equip_id, status
    FROM equipments;

    OPEN equip_cursor;

    read_loop: LOOP
        FETCH equip_cursor INTO v_equip_id, v_status;
        IF done = 1 THEN
            LEAVE read_loop;
        END IF;

        IF v_status IN ('Maintenance', 'Scrapped') THEN
            ITERATE read_loop;
        END IF;

        SELECT EXISTS(
            SELECT 1
            FROM borrowrecords
            WHERE equip_id = v_equip_id
              AND actual_return_date IS NULL
            LIMIT 1
        )
        INTO v_has_active;

        UPDATE equipments
        SET status = CASE WHEN v_has_active = 1 THEN 'Borrowed' ELSE 'Available' END
        WHERE equip_id = v_equip_id;
    END LOOP;

    CLOSE equip_cursor;

    DROP TEMPORARY TABLE IF EXISTS tmp_equipment_snapshot;
END $$

DROP PROCEDURE IF EXISTS sp_batch_transfer_available_equipment $$
CREATE PROCEDURE sp_batch_transfer_available_equipment(
    IN p_from_room_id INT,
    IN p_to_room_id INT,
    IN p_limit INT
)
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE v_equip_id INT;
    DECLARE v_transfer_count INT DEFAULT 0;

    DECLARE transfer_cursor CURSOR FOR
        SELECT equip_id
        FROM equipments
        WHERE room_id = p_from_room_id
          AND status = 'Available'
        ORDER BY purchase_date, equip_id;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    OPEN transfer_cursor;

    transfer_loop: LOOP
        FETCH transfer_cursor INTO v_equip_id;
        IF done = 1 OR v_transfer_count >= p_limit THEN
            LEAVE transfer_loop;
        END IF;

        UPDATE equipments
        SET room_id = p_to_room_id
        WHERE equip_id = v_equip_id;

        SET v_transfer_count = v_transfer_count + 1;
    END LOOP;

    CLOSE transfer_cursor;

    SELECT v_transfer_count AS transferred_count;
END $$

DELIMITER ;
