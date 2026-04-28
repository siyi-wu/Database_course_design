# 实验室设备管理系统设计说明书

## 1. 总体设计

系统采用数据库集中管理方式，将设备类别、实验室房间、用户、设备台账和借用记录拆分为 5 张核心业务表。数据库对象包括表、外键、索引、触发器、存储过程、函数和演示测试脚本。

## 2. 数据库设计

核心表包括：

- `categories`：保存设备类别。
- `labrooms`：保存实验室房间。
- `users`：保存借用人。
- `equipments`：保存设备台账。
- `borrowrecords`：保存借还流水。

核心约束包括：

- `equipments.category_id -> categories.category_id`
- `equipments.room_id -> labrooms.room_id`
- `borrowrecords.equip_id -> equipments.equip_id`
- `borrowrecords.user_id -> users.user_id`

## 3. 程序与数据库对象设计

- 建表与初始化：由 `Q145/01_schema_and_seed.sql` 完成。
- 游标过程：由 `Q145/02_cursor_procedures.sql` 完成。
- 索引分析：由 `Q145/03_index_analysis.sql` 和 benchmark 脚本完成。
- 触发器：由 `Q236/01_triggers.sql` 完成。
- 带参过程和函数：由 `Q236/02_parameterized_routines.sql` 完成。

## 4. 借还流程设计

借用流程：

1. 用户或管理员选择可用设备。
2. 调用 `sp_borrow_equipment`。
3. 过程写入借用记录。
4. 插入前触发器校验业务规则。
5. 插入后触发器将设备状态改为 `Borrowed`。

归还流程：

1. 用户或管理员选择未归还记录。
2. 调用 `sp_return_equipment`。
3. 过程写入实际归还日期。
4. 更新后触发器检查是否仍存在未归还记录。
5. 如果没有其他未归还记录，则将设备状态恢复为 `Available`。

## 5. 性能设计

系统对高频查询建立复合索引：

- `idx_equipments_category_status` 支持按类别和状态查设备。
- `idx_borrowrecords_user_borrow_date` 支持按用户查询最近借用记录。
- `idx_borrowrecords_equip_active` 支持按设备检查未归还记录。

这些索引既服务查询性能，也服务触发器和存储过程中的状态判断。
