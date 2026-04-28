# Q236 云数据库运行结果

运行环境：

- 数据库：MySQL 8.0 / InnoDB
- 数据库名：`<database_name>`
- 部署位置：配置的 MySQL 数据库
- 基础表结构：已由 `Q145/01_schema_and_seed.sql` 创建

## 1. 创建触发器

执行文件：

```sql
SOURCE Q236/01_triggers.sql;
```

已创建 3 个触发器：

- `trg_borrowrecords_before_insert`
- `trg_borrowrecords_after_insert`
- `trg_borrowrecords_after_update`

## 2. 创建带参过程和函数

执行文件：

```sql
SOURCE Q236/02_parameterized_routines.sql;
```

已创建 2 个带参存储过程：

- `sp_borrow_equipment(p_equip_id, p_user_id, p_borrow_date, p_days)`
- `sp_return_equipment(p_record_id, p_return_date)`

已创建 1 个带参函数：

- `fn_user_active_borrow_count(p_user_id)`

## 3. 演示测试

执行文件：

```sql
SOURCE Q236/04_demo_and_test.sql;
```

测试流程：

1. 自动选择一个可用设备和一个用户。
2. 调用 `sp_borrow_equipment` 借出设备。
3. 查询设备状态，确认触发器自动改为 `Borrowed`。
4. 调用 `sp_return_equipment` 归还设备。
5. 查询设备状态，确认触发器自动恢复为 `Available`。
6. 调用 `fn_user_active_borrow_count` 检查用户未归还数量变化。

## 4. 实际执行结果

本次云数据库演示自动选择：

- 用户编号：`1`
- 设备编号：`1`
- 新增借用记录编号：`4096`

借用前：

| demo_user_id | demo_equip_id | active_count_before |
| --- | --- | --- |
| 1 | 1 | 0 |

调用借用过程：

```sql
CALL sp_borrow_equipment(1, 1, '2026-04-27', 7);
```

返回结果：

| new_record_id | equip_id | message |
| --- | --- | --- |
| 4096 | 1 | 借用成功，设备状态已由触发器自动更新 |

借用后验证：

| record_id | equip_id | user_id | borrow_date | plan_return_date | actual_return_date | equipment_status_after_borrow | active_count_after_borrow |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 4096 | 1 | 1 | 2026-04-27 | 2026-05-04 | NULL | Borrowed | 1 |

调用归还过程：

```sql
CALL sp_return_equipment(4096, '2026-04-27');
```

返回结果：

| record_id | equip_id | message |
| --- | --- | --- |
| 4096 | 1 | 归还成功，设备状态已由触发器自动更新 |

归还后验证：

| record_id | equip_id | user_id | borrow_date | plan_return_date | actual_return_date | equipment_status_after_return | active_count_after_return |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 4096 | 1 | 1 | 2026-04-27 | 2026-05-04 | 2026-04-27 | Available | 0 |

## 5. 验证结论

云数据库中已成功创建并验证：

- `3` 个触发器均存在于 `borrowrecords` 表上。
- `2` 个带参存储过程均可调用。
- `1` 个带参函数可返回用户未归还数量。
- 借用设备时，设备状态自动变为 `Borrowed`。
- 归还设备时，设备状态自动恢复为 `Available`。
- 用户未归还数量在借用后由 `0` 变为 `1`，归还后由 `1` 回到 `0`。
