# 实验室设备管理系统测试报告

## 1. 测试环境

- 数据库：MySQL 8.0 / InnoDB
- 数据库名：`<database_name>`
- 基础数据：由 `Q145/01_schema_and_seed.sql` 生成
- 测试对象：Q236 触发器、带参存储过程、带参函数

## 2. 测试用例

### 用例 1：正常借用设备

操作：

```sql
CALL sp_borrow_equipment(@demo_equip_id, @demo_user_id, CURRENT_DATE(), 7);
```

预期结果：

- 新增一条 `borrowrecords` 记录。
- `actual_return_date` 为空。
- 对应设备状态变为 `Borrowed`。

### 用例 2：正常归还设备

操作：

```sql
CALL sp_return_equipment(@demo_record_id, CURRENT_DATE());
```

预期结果：

- 借用记录写入 `actual_return_date`。
- 对应设备状态恢复为 `Available`。

### 用例 3：重复借出同一设备

操作：

```sql
CALL sp_borrow_equipment(@demo_equip_id, @demo_user_id, CURRENT_DATE(), 7);
CALL sp_borrow_equipment(@demo_equip_id, @demo_user_id, CURRENT_DATE(), 7);
```

预期结果：

- 第二次借用失败。
- 触发器返回“该设备存在未归还记录，不能重复借出”。

### 用例 4：归还不存在的记录

操作：

```sql
CALL sp_return_equipment(-1, CURRENT_DATE());
```

预期结果：

- 存储过程返回“借用记录不存在”。

### 用例 5：查询用户未归还数量

操作：

```sql
SELECT fn_user_active_borrow_count(@demo_user_id);
```

预期结果：

- 借出后数量增加。
- 归还后数量恢复。

## 3. 测试结论

Q236 中的触发器、带参存储过程和带参函数能够完成设备借出、归还、状态自动维护和未归还数量统计，满足课程设计中 `(2)(3)` 的实现要求。规范化文档满足 `(6)` 的设计说明要求。
