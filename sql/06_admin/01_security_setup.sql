-- 本脚本用于说明正式部署时的最小权限账号方案。
-- 执行前请替换用户名、主机范围和强密码；不要在公开材料中保留真实密码。
-- 执行前请先 USE 目标数据库，或通过 mysql <database> < 本脚本 进入目标库。

CREATE USER IF NOT EXISTS 'lab_app'@'%' IDENTIFIED BY 'CHANGE_ME_STRONG_PASSWORD';

SET @target_database := DATABASE();
SET @grant_sql := CONCAT(
    'GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON `',
    REPLACE(@target_database, '`', '``'),
    '`.* TO ''lab_app''@''%'''
);

PREPARE grant_stmt FROM @grant_sql;
EXECUTE grant_stmt;
DEALLOCATE PREPARE grant_stmt;

FLUSH PRIVILEGES;

-- 验证授权：
-- SHOW GRANTS FOR 'lab_app'@'%';

-- 如需回收账号：
-- DROP USER IF EXISTS 'lab_app'@'%';
