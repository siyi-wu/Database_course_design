# 触发器、带参过程与规范化说明

本说明对应数据库课程设计中的数据库要求 `(2)(3)(6)`：

- `(2)` 至少包含三个触发器。
- `(3)` 至少包含两个带参存储过程或函数。
- `(6)` 描述应用规范化理论建立模式的详细过程。

系统主题沿用小组统一的“实验室设备管理系统”，基础表结构来自 `sql/01_schema/01_schema_and_seed.sql`，不在本目录重复建表。

## 文件说明

- `01_triggers.sql`：创建 3 个借还业务触发器。
- `02_parameterized_routines.sql`：创建 2 个带参存储过程和 1 个带参函数。
- `03_normalization_process.md`：规范化理论建模详细过程。
- `04_demo_and_test.sql`：云数据库演示与测试脚本。
- `05_cloud_run_results.md`：云数据库执行结果记录。

## 执行顺序

1. 确认 `sql/01_schema/01_schema_and_seed.sql` 已经在 `<database_name>` 中执行。
2. 执行 `sql/02_programmability/02_triggers.sql`。
3. 执行 `sql/02_programmability/03_parameterized_routines.sql`。
4. 执行 `sql/05_demo/01_demo_and_test.sql`。

## 关键对象

- 触发器：`trg_borrowrecords_before_insert`
- 触发器：`trg_borrowrecords_after_insert`
- 触发器：`trg_borrowrecords_after_update`
- 存储过程：`sp_borrow_equipment(p_equip_id, p_user_id, p_borrow_date, p_days)`
- 存储过程：`sp_return_equipment(p_record_id, p_return_date)`
- 函数：`fn_user_active_borrow_count(p_user_id)`

## 业务说明

借用设备时，调用 `sp_borrow_equipment` 插入借用记录。插入前触发器会检查设备状态、日期合法性和是否重复借出；插入后触发器会自动把设备状态改为 `Borrowed`。

归还设备时，调用 `sp_return_equipment` 更新实际归还日期。更新后触发器会检查该设备是否仍存在其他未归还记录，如果没有，则自动把设备状态恢复为 `Available`。
