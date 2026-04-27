# 本地 MySQL 运行结果

本次验证环境：

- MySQL 版本：`8.0.37`
- 默认存储引擎：`InnoDB`
- 本地数据库名：`<database_name>_local`

## 1. 表与数据量

系统共建立 5 张核心业务表，并已成功导入演示数据：

- `categories`：6 条
- `labrooms`：5 条
- `users`：120 条
- `equipments`：1500 条
- `borrowrecords`：3000 条

## 2. 参照关系

成功建立 4 个外键约束：

- `equipments.category_id -> categories.category_id`
- `equipments.room_id -> labrooms.room_id`
- `borrowrecords.equip_id -> equipments.equip_id`
- `borrowrecords.user_id -> users.user_id`

## 3. 二级索引

建立的二级索引如下：

- `idx_equipments_category_status(category_id, status)`
- `idx_borrowrecords_user_borrow_date(user_id, borrow_date DESC)`
- `idx_borrowrecords_equip_active(equip_id, actual_return_date, plan_return_date)`

## 4. 游标存储过程运行结果

### 4.1 `sp_sync_equipment_status()`

执行前设备状态统计：

- `Available`：1364
- `Maintenance`：88
- `Scrapped`：48

执行后设备状态统计：

- `Available`：1091
- `Borrowed`：273
- `Maintenance`：88
- `Scrapped`：48

说明：该过程逐个检查设备是否存在“未归还借用记录”，并把设备状态同步为 `Borrowed` 或 `Available`。本次执行耗时约 `2.998s`。

### 4.2 `sp_batch_transfer_available_equipment(1, 2, 5)`

执行前各实验室设备数量：

- 房间 1：300
- 房间 2：300
- 房间 3：300
- 房间 4：300
- 房间 5：300

执行结果：

- 返回 `transferred_count = 5`

执行后各实验室设备数量：

- 房间 1：295
- 房间 2：305
- 房间 3：300
- 房间 4：300
- 房间 5：300

说明：该过程使用游标逐个转移指定数量的“可用设备”，本次执行耗时约 `0.078s`。

## 5. 索引性能分析

### 查询 1：按类别和状态筛选设备

查询语句：

```sql
SELECT equip_id, equip_name, status
FROM equipments
WHERE category_id = 3
  AND status = 'Available';
```

未建立复合索引前，执行计划使用 `category_id` 上的普通索引查出约 250 行，再继续过滤 `status`。

建立 `idx_equipments_category_status(category_id, status)` 后，执行计划变为：

```text
Index lookup on equipments using idx_equipments_category_status
```

说明：优化器可以同时利用 `category_id` 和 `status` 两个条件直接定位目标数据，减少回表和过滤成本。

### 查询 2：查询某用户最近借用记录

查询语句：

```sql
SELECT record_id, user_id, equip_id, borrow_date
FROM borrowrecords
WHERE user_id = 42
ORDER BY borrow_date DESC
LIMIT 10;
```

未建立复合索引前，执行计划先按 `user_id` 找到约 25 行数据，再执行排序：

```text
Sort: borrowrecords.borrow_date DESC
```

建立 `idx_borrowrecords_user_borrow_date(user_id, borrow_date DESC)` 后，执行计划变为：

```text
Index lookup on borrowrecords using idx_borrowrecords_user_borrow_date
```

说明：优化器可直接按照复合索引顺序返回数据，避免额外排序，特别适合“条件过滤 + 排序 + limit”这类查询。
