# 实验室设备管理系统设计说明书

## 1. 设计目标

本系统采用 MySQL 8.0 / InnoDB 作为核心数据库，围绕实验室设备台账、借出、归还、查询统计和管理维护设计数据库对象与配套 UI。设计目标是让业务规则尽量沉淀到数据库层，应用界面通过接口调用数据库过程和查询结果完成演示。

本文档对应课程评分中的“设计文档”，ER 模型见 `docs/analysis/02_er_model.md`，规范化过程见 `docs/design/02_normalization_design_part_1_4_5.md` 和 `docs/design/03_normalization_process_part_2_3_6.md`。

## 2. 总体架构

系统分为三层：

| 层次 | 技术与文件 | 职责 |
| --- | --- | --- |
| 数据库层 | `sql/` | 建表、外键、初始化数据、触发器、存储过程、函数、视图、索引、事务演示 |
| 服务层 | `ui/server/index.js` | 使用 Express + mysql2 连接数据库，提供 REST API |
| 界面层 | `ui/src/main.jsx`、`ui/src/styles.css` | 提供总览、设备、借还、用户、房间、类别、记录和数据库功能演示页面 |

服务端读取根目录 `config.txt` 中的连接信息，前端通过 Vite 代理访问后端接口。数据库对象是系统核心，UI 主要用于便捷演示和验收。

## 3. 数据库结构设计

系统包含 5 张核心业务表：

| 表名 | 说明 | 关键字段 |
| --- | --- | --- |
| `categories` | 设备类别 | `category_id`、`category_name`、`description` |
| `labrooms` | 实验室房间 | `room_id`、`room_name`、`location`、`admin_name` |
| `users` | 借用用户 | `user_id`、`user_name`、`role`、`contact` |
| `equipments` | 设备台账 | `equip_id`、`equip_name`、`category_id`、`room_id`、`status`、`price`、`purchase_date` |
| `borrowrecords` | 借还流水 | `record_id`、`equip_id`、`user_id`、`borrow_date`、`plan_return_date`、`actual_return_date` |

核心参照关系：

- `equipments.category_id -> categories.category_id`
- `equipments.room_id -> labrooms.room_id`
- `borrowrecords.equip_id -> equipments.equip_id`
- `borrowrecords.user_id -> users.user_id`

外键均采用 `ON UPDATE CASCADE ON DELETE RESTRICT`。这样主键更新时从表同步更新，被历史记录引用的数据不能误删，适合课程设计中的完整性要求。

## 4. 数据类型与约束设计

- 主键均使用 `INT AUTO_INCREMENT`，便于演示和关联。
- 名称字段使用 `VARCHAR`，说明字段使用 `TEXT`。
- 设备价格使用 `DECIMAL(10,2)`，避免浮点误差。
- 日期使用 `DATE`，符合借用和归还业务粒度。
- 用户角色使用 `ENUM('Teacher', 'Student', 'Staff')`。
- 设备状态使用 `ENUM('Available', 'Borrowed', 'Maintenance', 'Scrapped')`。
- 类别名称和房间名称设置唯一约束，减少基础资料重复。

## 5. 数据库对象设计

| 对象 | 文件 | 设计说明 |
| --- | --- | --- |
| 建表与种子数据 | `sql/01_schema/01_schema_and_seed.sql` | 创建 5 张核心表，并生成类别、房间、用户、设备和借用记录演示数据 |
| 游标过程 | `sql/02_programmability/01_cursor_procedures.sql` | `sp_sync_equipment_status` 批量同步设备状态；`sp_batch_transfer_available_equipment` 批量调拨可用设备 |
| 触发器 | `sql/02_programmability/02_triggers.sql` | 借用前校验日期、状态和重复借出；借用后更新设备状态；归还后恢复设备状态 |
| 带参过程与函数 | `sql/02_programmability/03_parameterized_routines.sql` | `sp_borrow_equipment`、`sp_return_equipment`、`fn_user_active_borrow_count` |
| 视图 | `sql/02_programmability/04_views.sql` | `v_equipment_detail` 和 `v_borrowrecord_detail` 封装多表查询 |
| 事务演示 | `sql/02_programmability/05_transaction_demo.sql` | `sp_borrow_equipment_tx` 使用事务和行级锁演示并发控制 |
| 索引分析 | `sql/03_indexes/01_index_analysis.sql` | 创建二级索引并通过 `EXPLAIN` 对比执行计划 |
| 安全授权 | `sql/06_admin/01_security_setup.sql` | 提供最小权限账号授权模板 |

## 6. 借还流程设计

借用流程：

1. 用户在 UI 选择可用设备、借用用户、借用日期和天数。
2. 后端调用 `sp_borrow_equipment` 或事务版本 `sp_borrow_equipment_tx`。
3. 存储过程检查设备、用户、日期和天数参数。
4. 插入 `borrowrecords` 前，触发器再次校验设备状态和未归还记录。
5. 插入成功后，触发器将设备状态改为 `Borrowed`。
6. 过程返回新借用记录编号，UI 刷新设备和记录列表。

归还流程：

1. 用户在 UI 输入未归还记录编号和归还日期。
2. 后端调用 `sp_return_equipment`。
3. 存储过程检查记录是否存在、是否已归还、归还日期是否合法。
4. 更新 `actual_return_date`。
5. 更新后触发器检查同一设备是否仍存在未归还记录。
6. 若不存在未归还记录，则设备状态恢复为 `Available`。

## 7. 查询与接口设计

后端提供以下主要接口：

- `/api/stats`：总览统计。
- `/api/categories`、`/api/rooms`、`/api/users`、`/api/equipments`：基础资料 CRUD。
- `/api/records`：借用记录查询。
- `/api/borrow`：调用借用存储过程。
- `/api/return`：调用归还存储过程。
- `/api/users/:id/active-count`：调用用户未归还数量函数。
- `/api/views/equipment-detail`、`/api/views/borrowrecord-detail`：查询视图。
- `/api/admin/sync-status`、`/api/admin/batch-transfer`：演示游标过程。

服务端使用 mysql2 的命名参数和参数化查询，避免把用户输入直接拼入 SQL 值位置。

## 8. 索引与性能设计

系统建立以下二级索引：

- `idx_equipments_category_status`：服务按类别和状态筛选设备。
- `idx_borrowrecords_user_borrow_date`：服务按用户查询最近借用记录，并支持按日期倒序。
- `idx_borrowrecords_equip_active`：服务按设备检查未归还记录，辅助触发器和借用过程。

性能测试材料见 `docs/testing/03_benchmark_results.md`。其中用户借用记录查询从“全表扫描 + 排序”优化为直接使用复合索引，效果最明显。

## 9. 事务与并发控制设计

普通借用过程已经通过触发器避免重复借出。为了展示事务处理与并发控制，系统额外提供 `sp_borrow_equipment_tx`：

- 使用 `START TRANSACTION` 开启事务。
- 使用 `SELECT ... FOR UPDATE` 锁定目标设备行。
- 发生异常时由 `EXIT HANDLER` 执行 `ROLLBACK`。
- 正常插入借用记录后执行 `COMMIT`。

该设计可用于说明多用户同时借用同一设备时，数据库如何通过 InnoDB 行级锁串行化关键判断。

## 10. 备份恢复与安全设计

- `scripts/backup_database.sh` 使用 `mysqldump --single-transaction --routines --triggers --events` 备份表、数据和数据库对象。
- `scripts/restore_database.sh` 使用 `mysql` 恢复备份文件，并要求输入 `YES` 确认。
- `scripts/init_database.sh` 可按依赖顺序初始化数据库，支持跳过 benchmark 和选择性执行安全授权。
- `sql/06_admin/01_security_setup.sql` 用于创建应用访问账号并限制权限。

## 11. 设计结论

本设计将基础数据、业务流水和数据库可编程对象分层组织，既满足课程对数据库设计、规范化、触发器、存储过程、游标、索引和事务的要求，也提供可运行 UI 便于验收演示。核心一致性由数据库层保证，界面和服务层负责交互与展示。
