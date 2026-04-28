# 实验室设备管理系统操作手册

## 1. 初始化

首次部署时执行：

```sql
SOURCE sql/01_schema/01_schema_and_seed.sql;
SOURCE sql/02_programmability/01_cursor_procedures.sql;
SOURCE sql/03_indexes/01_index_analysis.sql;
SOURCE sql/02_programmability/02_triggers.sql;
SOURCE sql/02_programmability/03_parameterized_routines.sql;
SOURCE sql/02_programmability/04_views.sql;
SOURCE sql/02_programmability/05_transaction_demo.sql;
```

如果配置的 MySQL 数据库中已经存在基础表、游标过程和索引，只需执行触发器、带参过程和函数、视图、事务演示脚本。

## 2. 借用设备

```sql
CALL sp_borrow_equipment(设备编号, 用户编号, CURRENT_DATE(), 借用天数);
```

示例：

```sql
CALL sp_borrow_equipment(1, 1, CURRENT_DATE(), 7);
```

借用成功后，设备状态会由触发器自动改为 `Borrowed`。

## 3. 归还设备

```sql
CALL sp_return_equipment(借用记录编号, CURRENT_DATE());
```

示例：

```sql
CALL sp_return_equipment(3001, CURRENT_DATE());
```

归还成功后，如果该设备没有其他未归还记录，设备状态会由触发器自动恢复为 `Available`。

## 4. 查询用户未归还数量

```sql
SELECT fn_user_active_borrow_count(用户编号) AS active_count;
```

## 5. 查看数据库对象

查看触发器：

```sql
SHOW TRIGGERS WHERE `Table` = 'borrowrecords';
```

查看存储过程：

```sql
SHOW PROCEDURE STATUS WHERE Db = DATABASE();
```

查看函数：

```sql
SHOW FUNCTION STATUS WHERE Db = DATABASE();
```

查看视图：

```sql
SHOW FULL TABLES WHERE Table_type = 'VIEW';
SELECT * FROM v_equipment_detail LIMIT 10;
SELECT * FROM v_borrowrecord_detail LIMIT 10;
```

## 6. 事务借用演示

```sql
CALL sp_borrow_equipment_tx(设备编号, 用户编号, CURRENT_DATE(), 7);
```

该过程使用显式事务和 `SELECT ... FOR UPDATE` 锁定设备行，用于展示并发借用场景下的事务控制思路。

## 7. 备份与恢复

备份数据库：

```bash
scripts/backup_database.sh
```

恢复数据库：

```bash
scripts/restore_database.sh backups/备份文件.sql
```

详细说明见 `docs/manual/02_backup_restore_manual.md`。
