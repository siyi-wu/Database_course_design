# 事务与并发控制测试说明

## 1. 测试目标

本测试用于说明系统在借用设备场景下的事务处理和并发控制思路。原有 `sp_borrow_equipment` 已经通过触发器阻止重复借出；补充的 `sp_borrow_equipment_tx` 进一步使用显式事务和 `SELECT ... FOR UPDATE` 锁定设备行，便于在答辩时展示事务控制。

## 2. 相关对象

- 事务演示过程：`sp_borrow_equipment_tx`
- SQL 文件：`sql/02_programmability/05_transaction_demo.sql`
- 关键语句：`START TRANSACTION`、`FOR UPDATE`、`COMMIT`、`ROLLBACK`

## 3. 测试步骤

选择一台可用设备和一个用户：

```sql
SELECT equip_id
FROM equipments
WHERE status = 'Available'
LIMIT 1;
```

调用事务借用过程：

```sql
CALL sp_borrow_equipment_tx(设备编号, 用户编号, CURRENT_DATE(), 7);
```

再次对同一设备调用：

```sql
CALL sp_borrow_equipment_tx(设备编号, 用户编号, CURRENT_DATE(), 7);
```

## 4. 预期结果

- 第一次调用成功，新增借用记录。
- 触发器自动把设备状态改为 `Borrowed`。
- 第二次调用失败，提示该设备存在未归还记录。
- 如果过程执行中发生异常，`EXIT HANDLER` 会执行 `ROLLBACK`，避免留下半完成状态。

## 5. 并发控制说明

`sp_borrow_equipment_tx` 在事务中使用：

```sql
SELECT status
FROM equipments
WHERE equip_id = p_equip_id
FOR UPDATE;
```

该语句会锁定目标设备行，使并发借用同一设备时，一个事务必须等待另一个事务完成后才能继续判断状态和插入借用记录。配合触发器中的未归还记录检查，可以降低并发情况下重复借出的风险。

## 6. 测试结论

项目已具备基于 InnoDB 的事务支持，并补充了显式事务和行级锁演示过程。该内容可用于回应评分标准中“事务处理与并发控制”的要求。

## 7. 配置的 MySQL 数据库验证记录

已在配置的 MySQL 数据库 `<database_name>` 中执行 `sql/02_programmability/05_transaction_demo.sql` 创建 `sp_borrow_equipment_tx`。

验证流程：

1. 自动选择一台 `Available` 且不存在未归还记录的设备。
2. 调用 `CALL sp_borrow_equipment_tx(...);`。
3. 新增借用记录编号为 `4097`。
4. 随后调用 `CALL sp_return_equipment(4097, CURRENT_DATE());` 归还。
5. 查询设备状态，确认设备恢复为 `Available`。

验证结论：事务演示过程可以正常借出设备，归还后触发器能够恢复设备状态。
