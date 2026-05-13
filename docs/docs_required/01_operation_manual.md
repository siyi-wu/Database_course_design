# 实验室设备管理系统操作手册

## 1. 适用范围

本文档用于指导教师验收、答辩演示和本地部署运行实验室设备管理系统。系统包含 MySQL 数据库脚本、Express 后端、React 前端、备份恢复脚本和测试材料。

备份恢复专项说明见 `docs/manual/02_backup_restore_manual.md`。

## 2. 环境准备

需要准备：

- MySQL 8.0 或兼容版本。
- Node.js 与 npm。
- bash 终端环境。
- 可访问 MySQL 的账号，初始化阶段需要具备建库、建表、创建过程、触发器和索引权限。

复制配置文件：

```bash
cp config.example.txt config.txt
```

修改 `config.txt`：

```text
host: your-mysql-host
port: 3306
username: your-username
password: your-password
database: your-database-name
```

## 3. 初始化数据库

推荐使用初始化脚本：

```bash
scripts/init_database.sh --skip-benchmark
```

该命令会读取 `config.txt`，重建目标数据库，并导入核心表、种子数据、游标过程、触发器、带参过程、函数、视图、事务过程、索引和演示 SQL。`--skip-benchmark` 用于跳过大规模性能测试数据，适合快速部署和课堂演示。

如果需要完整性能测试数据：

```bash
scripts/init_database.sh
```

如果需要同时执行安全授权模板：

```bash
scripts/init_database.sh --skip-benchmark --with-security
```

也可以在 MySQL 客户端中按顺序手工执行：

```sql
SOURCE sql/01_schema/01_schema_and_seed.sql;
SOURCE sql/02_programmability/01_cursor_procedures.sql;
SOURCE sql/02_programmability/02_triggers.sql;
SOURCE sql/02_programmability/03_parameterized_routines.sql;
SOURCE sql/02_programmability/04_views.sql;
SOURCE sql/02_programmability/05_transaction_demo.sql;
SOURCE sql/03_indexes/01_index_analysis.sql;
SOURCE sql/05_demo/01_demo_and_test.sql;
```

## 4. 启动 UI

安装依赖：

```bash
cd ui
npm install
```

启动前后端：

```bash
npm run dev
```

默认访问地址：

```text
http://localhost:5173/
```

默认后端地址：

```text
http://localhost:3001/
```

如页面提示数据库连接失败，优先检查根目录 `config.txt` 是否存在、数据库账号是否正确、数据库是否已初始化。

## 5. 常用业务操作

### 5.1 查询设备

在 UI 的“设备”页中，可以按设备名称、设备编号、状态、类别和房间筛选设备。也可以直接执行 SQL：

```sql
SELECT equip_id, equip_name, category_id, room_id, status
FROM equipments
WHERE status = 'Available'
LIMIT 10;
```

### 5.2 借用设备

UI 操作：进入“借还”页，填写设备编号、用户编号、借用日期和借用天数，点击借出。

SQL 操作：

```sql
CALL sp_borrow_equipment(设备编号, 用户编号, CURRENT_DATE(), 7);
```

借用成功后，系统会新增一条 `borrowrecords` 记录，设备状态由触发器自动改为 `Borrowed`。

如果要演示事务版本：

```sql
CALL sp_borrow_equipment_tx(设备编号, 用户编号, CURRENT_DATE(), 7);
```

### 5.3 归还设备

UI 操作：在“借还”页填写未归还记录编号和归还日期，点击归还。

SQL 操作：

```sql
CALL sp_return_equipment(借用记录编号, CURRENT_DATE());
```

归还成功后，系统写入 `actual_return_date`。如果该设备没有其他未归还记录，触发器会将设备状态恢复为 `Available`。

### 5.4 查询用户未归还数量

```sql
SELECT fn_user_active_borrow_count(用户编号) AS active_count;
```

UI 的“用户”页会显示每个用户当前未归还数量。

### 5.5 使用视图查询详情

```sql
SELECT *
FROM v_equipment_detail
LIMIT 10;

SELECT *
FROM v_borrowrecord_detail
ORDER BY record_id DESC
LIMIT 10;
```

UI 的“数据库功能”页也提供了设备详情视图和借用详情视图的查询入口。

### 5.6 演示游标过程

同步设备状态：

```sql
CALL sp_sync_equipment_status();
```

批量调拨指定房间中的可用设备：

```sql
CALL sp_batch_transfer_available_equipment(源房间编号, 目标房间编号, 调拨数量);
```

## 6. 查看数据库对象

查看表：

```sql
SHOW TABLES;
```

查看触发器：

```sql
SHOW TRIGGERS;
```

查看过程和函数：

```sql
SHOW PROCEDURE STATUS WHERE Db = DATABASE();
SHOW FUNCTION STATUS WHERE Db = DATABASE();
```

查看索引：

```sql
SHOW INDEX FROM equipments;
SHOW INDEX FROM borrowrecords;
```

查看建表语句：

```sql
SHOW CREATE TABLE equipments;
SHOW CREATE TABLE borrowrecords;
```

## 7. 备份与恢复

备份数据库：

```bash
scripts/backup_database.sh
```

指定备份文件：

```bash
scripts/backup_database.sh backups/lab_equipment_demo.sql
```

恢复数据库：

```bash
scripts/restore_database.sh backups/lab_equipment_demo.sql
```

恢复脚本会要求输入 `YES` 确认，避免误覆盖数据。备份文件包含表结构、数据、存储过程、函数、触发器和事件。

## 8. 推荐验收演示流程

1. 打开 `docs/course/question.md`，说明课程要求。
2. 打开 `docs/course_design_full_report.md`，说明项目总体结构和要求对应关系。
3. 展示 `docs/analysis/01_requirement_analysis.md` 和 `docs/analysis/02_er_model.md`，说明需求与 ER 模型。
4. 展示 `docs/design/01_system_design.md` 和规范化文档，说明关系模式、外键、触发器、过程、游标和索引设计。
5. 在 MySQL 中执行 `SHOW TABLES;`、`SHOW TRIGGERS;`、`SHOW PROCEDURE STATUS WHERE Db = DATABASE();`。
6. 启动 UI，展示总览统计、设备筛选、基础资料维护。
7. 选择一台可用设备，演示借出；再次借出同一设备，展示触发器错误提示。
8. 演示归还设备，确认设备状态恢复。
9. 展示“数据库功能”页中的视图、用户未归还数量、状态同步和批量调拨。
10. 打开 `docs/testing/01_test_report.md`、`docs/testing/03_benchmark_results.md` 和 `docs/testing/06_transaction_concurrency_test.md`，说明测试和性能结果。
11. 展示 `scripts/backup_database.sh` 和 `scripts/restore_database.sh`，说明备份恢复方案。

## 9. 常见问题

数据库连接失败：

- 检查 `config.txt` 是否在项目根目录。
- 检查 host、port、username、password、database 是否正确。
- 确认 MySQL 服务正在运行。

借用设备失败：

- 检查设备是否为 `Available`。
- 检查设备是否已有未归还记录。
- 检查用户编号是否存在。
- 检查借用天数是否为正数。

删除基础资料失败：

- 被外键引用的类别、房间、用户或设备不能直接删除。需要先处理相关引用记录，或保留历史数据以保证审计完整性。

性能测试耗时较长：

- 初始化时使用 `--skip-benchmark` 可跳过大规模 benchmark 数据。
- 需要展示索引性能时再执行 `sql/04_benchmark/01_benchmark_setup.sql` 和 `sql/04_benchmark/02_benchmark_queries.sql`。
