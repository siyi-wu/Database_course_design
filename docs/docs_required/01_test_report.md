# 实验室设备管理系统测试报告

## 1. 测试目的

本文档用于验证实验室设备管理系统是否满足课程设计中的功能实现、数据库高级功能、界面交互、性能优化和数据一致性要求。测试重点包括建表与完整性约束、CRUD、触发器、存储过程、函数、游标过程、视图、事务并发控制、索引性能和 UI 调用数据库对象的结果。

更多专项测试材料见：

- `docs/testing/03_benchmark_results.md`：索引性能对比。
- `docs/testing/05_ui_test_report.md`：UI 功能测试。
- `docs/testing/06_transaction_concurrency_test.md`：事务与并发控制测试。

## 2. 测试环境

| 项目 | 内容 |
| --- | --- |
| 数据库 | MySQL 8.0 / InnoDB |
| 字符集 | `utf8mb4` |
| 后端 | Express + mysql2 |
| 前端 | React + Vite |
| 初始化脚本 | `scripts/init_database.sh` 或按 README 顺序执行 SQL |
| 基础数据 | 6 类设备类别、5 个实验室房间、120 个用户、1500 台设备、3000 条借用记录 |

## 3. 测试范围

- 表结构、主键、唯一约束、外键和枚举字段。
- 设备、用户、房间、类别的增删改查。
- 借用和归还存储过程。
- 借用前、借用后、归还后三个触发器。
- 用户未归还数量函数。
- 两个游标存储过程。
- 两个业务视图。
- 显式事务借用过程。
- 二级索引和查询执行计划。
- 前后端接口与错误提示。
- 备份恢复脚本可用性检查。

## 4. 测试用例

| 编号 | 测试项 | 操作 | 预期结果 | 结论 |
| --- | --- | --- | --- | --- |
| DB-01 | 初始化数据库 | 执行 `scripts/init_database.sh --skip-benchmark` | 5 张核心表、触发器、过程、函数、视图和索引创建成功 | 通过 |
| DB-02 | 外键约束 | 插入不存在类别或房间的设备 | 插入失败，数据库返回外键错误 | 通过 |
| DB-03 | 唯一约束 | 插入重复 `category_name` 或 `room_name` | 插入失败，数据库返回唯一约束错误 | 通过 |
| CRUD-01 | 新增设备 | 插入合法设备数据 | `equipments` 新增记录 | 通过 |
| CRUD-02 | 修改设备 | 修改设备价格、状态或房间 | 对应字段更新成功 | 通过 |
| CRUD-03 | 删除被引用设备 | 删除已有借用记录引用的设备 | 外键阻止删除，历史记录保持有效 | 通过 |
| SP-01 | 正常借用 | `CALL sp_borrow_equipment(设备编号, 用户编号, CURRENT_DATE(), 7);` | 新增未归还记录，设备状态变为 `Borrowed` | 通过 |
| SP-02 | 正常归还 | `CALL sp_return_equipment(记录编号, CURRENT_DATE());` | 写入实际归还日期，设备恢复为 `Available` | 通过 |
| SP-03 | 参数校验 | 借用天数小于等于 0 | 存储过程拒绝操作 | 通过 |
| TR-01 | 重复借出 | 对同一未归还设备再次借用 | 触发器提示“该设备存在未归还记录，不能重复借出” | 通过 |
| TR-02 | 维修设备借出 | 借用 `Maintenance` 状态设备 | 触发器提示维修或报废设备不能借出 | 通过 |
| TR-03 | 日期校验 | 计划归还日期早于借用日期 | 触发器拒绝插入 | 通过 |
| FN-01 | 未归还统计 | `SELECT fn_user_active_borrow_count(用户编号);` | 返回该用户未归还记录数量 | 通过 |
| CUR-01 | 状态同步 | `CALL sp_sync_equipment_status();` | 批量检查借用记录并同步设备状态 | 通过 |
| CUR-02 | 批量调拨 | `CALL sp_batch_transfer_available_equipment(源房间, 目标房间, 数量);` | 返回调拨数量，设备房间更新 | 通过 |
| VIEW-01 | 设备详情视图 | 查询 `v_equipment_detail` | 返回设备、类别、房间和管理员信息 | 通过 |
| VIEW-02 | 借用详情视图 | 查询 `v_borrowrecord_detail` | 返回设备、用户和记录状态 | 通过 |
| TX-01 | 事务借用 | `CALL sp_borrow_equipment_tx(...);` | 使用事务完成借用，异常时回滚 | 通过 |
| IDX-01 | 设备筛选索引 | 对类别与状态查询执行 `EXPLAIN` | 使用 `idx_equipments_category_status` | 通过 |
| IDX-02 | 用户借用记录索引 | 对用户最近记录查询执行 `EXPLAIN` | 使用 `idx_borrowrecords_user_borrow_date` | 通过 |
| UI-01 | 前端总览 | 打开 `http://localhost:5173/` | 显示统计数据和数据库连接状态 | 通过 |
| UI-02 | 前端借还 | 在 UI 中借出、归还设备 | UI 调用存储过程并刷新状态 | 通过 |
| BK-01 | 备份脚本 | 执行 `scripts/backup_database.sh` | 生成包含表、数据、触发器、过程和函数的 SQL 文件 | 通过 |

## 5. 关键 SQL 验证示例

正常借用：

```sql
SELECT equip_id
FROM equipments
WHERE status = 'Available'
LIMIT 1;

CALL sp_borrow_equipment(设备编号, 1, CURRENT_DATE(), 7);
```

重复借出校验：

```sql
CALL sp_borrow_equipment(同一设备编号, 1, CURRENT_DATE(), 7);
```

预期结果：第二次调用失败，错误信息为“该设备存在未归还记录，不能重复借出”。

正常归还：

```sql
CALL sp_return_equipment(借用记录编号, CURRENT_DATE());

SELECT status
FROM equipments
WHERE equip_id = 设备编号;
```

预期结果：借用记录写入 `actual_return_date`，设备状态恢复为 `Available`。

用户未归还数量：

```sql
SELECT fn_user_active_borrow_count(1) AS active_count;
```

## 6. 性能测试结论

系统针对高频查询设计了复合索引。根据 `docs/testing/03_benchmark_results.md` 的记录：

- 设备按类别和状态查询由全表扫描优化为复合索引查找。
- 用户最近借用记录查询由“全表扫描 + 排序”优化为直接使用 `(user_id, borrow_date DESC)` 索引。
- 返回结果较多的查询仍会受到结果传输影响；选择性较高并包含排序和 `LIMIT` 的查询优化效果最明显。

## 7. UI 测试结论

UI 已覆盖总览、设备、借还、用户、房间、类别、记录和数据库功能演示模块。前端借用和归还操作不是只修改页面状态，而是通过后端实际调用 `sp_borrow_equipment`、`sp_borrow_equipment_tx`、`sp_return_equipment` 等数据库对象。数据库返回的错误信息会展示到界面，便于演示输入校验和触发器拦截效果。

## 8. 测试风险与改进

- 当前测试以手工 SQL、UI 操作和文档化结果为主，没有引入自动化测试框架。
- 并发测试以事务过程和说明性验证为主，未使用压力测试工具模拟大量并发用户。
- 安全授权脚本是模板，正式部署时需要替换账号和密码。

这些风险不影响课程设计核心功能验收，但可作为后续工程化改进方向。

## 9. 总体结论

测试结果表明，系统能够完成实验室设备管理的基础 CRUD、借出归还、状态自动维护、异常拦截、统计查询、视图查询、游标批处理、事务演示、索引优化和备份恢复说明，满足课程设计中“功能实现”“高级功能实现”“扩展功能”“界面与交互”和“测试报告”的评分要求。
