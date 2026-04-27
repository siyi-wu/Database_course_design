SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS borrowrecords;
DROP TABLE IF EXISTS equipments;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS labrooms;
DROP TABLE IF EXISTS categories;

CREATE TABLE categories (
    category_id INT NOT NULL AUTO_INCREMENT,
    category_name VARCHAR(50) NOT NULL,
    description TEXT,
    PRIMARY KEY (category_id),
    UNIQUE KEY uk_categories_name (category_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE labrooms (
    room_id INT NOT NULL AUTO_INCREMENT,
    room_name VARCHAR(50) NOT NULL,
    location VARCHAR(100),
    admin_name VARCHAR(50),
    PRIMARY KEY (room_id),
    UNIQUE KEY uk_labrooms_name (room_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE users (
    user_id INT NOT NULL AUTO_INCREMENT,
    user_name VARCHAR(50) NOT NULL,
    role ENUM('Teacher', 'Student', 'Staff') DEFAULT 'Student',
    contact VARCHAR(20),
    PRIMARY KEY (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE equipments (
    equip_id INT NOT NULL AUTO_INCREMENT,
    equip_name VARCHAR(100) NOT NULL,
    category_id INT NOT NULL,
    room_id INT NOT NULL,
    status ENUM('Available', 'Borrowed', 'Maintenance', 'Scrapped') DEFAULT 'Available',
    price DECIMAL(10, 2),
    purchase_date DATE,
    PRIMARY KEY (equip_id),
    CONSTRAINT fk_equipments_category
        FOREIGN KEY (category_id) REFERENCES categories (category_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_equipments_room
        FOREIGN KEY (room_id) REFERENCES labrooms (room_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE borrowrecords (
    record_id INT NOT NULL AUTO_INCREMENT,
    equip_id INT NOT NULL,
    user_id INT NOT NULL,
    borrow_date DATE NOT NULL,
    plan_return_date DATE NOT NULL,
    actual_return_date DATE DEFAULT NULL,
    PRIMARY KEY (record_id),
    CONSTRAINT fk_borrowrecords_equipment
        FOREIGN KEY (equip_id) REFERENCES equipments (equip_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_borrowrecords_user
        FOREIGN KEY (user_id) REFERENCES users (user_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;

INSERT INTO categories (category_name, description) VALUES
('显微设备', '包含生物显微镜、金相显微镜等观察设备'),
('测量仪器', '包含万用表、示波器、功率分析仪等仪器'),
('计算设备', '包含工作站、GPU 服务器、便携终端等'),
('网络设备', '包含交换机、路由器、无线接入设备等'),
('安全设备', '包含消防、监控、门禁及安全检测设备'),
('电源设备', '包含 UPS、稳压器和实验电源系统');

INSERT INTO labrooms (room_name, location, admin_name) VALUES
('电子实验室A101', '科技楼A座1层', '王海'),
('电子实验室A102', '科技楼A座1层', '张敏'),
('创新实验室B201', '科技楼B座2层', '李哲'),
('精密测量室B202', '科技楼B座2层', '陈蕾'),
('网络工程室C301', '实训楼C座3层', '赵峰');

SET SESSION cte_max_recursion_depth = 5000;

INSERT INTO users (user_name, role, contact)
WITH RECURSIVE seq AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 120
)
SELECT
    CONCAT('用户', LPAD(n, 3, '0')),
    CASE
        WHEN MOD(n, 10) = 0 THEN 'Teacher'
        WHEN MOD(n, 3) = 0 THEN 'Staff'
        ELSE 'Student'
    END,
    CONCAT('138', LPAD(n, 8, '0'))
FROM seq;

INSERT INTO equipments (equip_name, category_id, room_id, status, price, purchase_date)
WITH RECURSIVE seq AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 1500
)
SELECT
    CONCAT('设备', LPAD(n, 4, '0')),
    MOD(n - 1, 6) + 1,
    MOD(n - 1, 5) + 1,
    CASE
        WHEN MOD(n, 17) = 0 THEN 'Maintenance'
        WHEN MOD(n, 29) = 0 THEN 'Scrapped'
        ELSE 'Available'
    END,
    800 + n * 7,
    DATE_ADD('2021-01-01', INTERVAL MOD(n * 3, 1200) DAY)
FROM seq;

INSERT INTO borrowrecords (equip_id, user_id, borrow_date, plan_return_date, actual_return_date)
WITH RECURSIVE seq AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 3000
)
SELECT
    MOD(n - 1, 1500) + 1,
    MOD(n - 1, 120) + 1,
    DATE_ADD('2024-01-01', INTERVAL MOD(n * 5, 700) DAY),
    DATE_ADD(DATE_ADD('2024-01-01', INTERVAL MOD(n * 5, 700) DAY), INTERVAL MOD(n, 7) + 3 DAY),
    CASE
        WHEN MOD(n, 5) = 0 THEN NULL
        WHEN MOD(n, 11) = 0 THEN DATE_ADD(DATE_ADD('2024-01-01', INTERVAL MOD(n * 5, 700) DAY), INTERVAL MOD(n, 7) + 12 DAY)
        ELSE DATE_ADD(DATE_ADD('2024-01-01', INTERVAL MOD(n * 5, 700) DAY), INTERVAL MOD(n, 4) + 1 DAY)
    END
FROM seq;
