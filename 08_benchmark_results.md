# VSCode 查看方法与索引性能对比

## 1. 在 VSCode MySQL Database Client 中查看“服务器上的实现”

你截图里的连接树已经能看到：

- `<database_name>`
- `Tables (5)`
- `Functions`
- `Procedures (2)`

推荐这样看：

### 看表结构

1. 展开 `<database_name> -> Tables`
2. 点击某张表，例如 `equipments`
3. 通常插件会打开该表的信息页，可以看到列、主键、外键、索引
4. 如果有右键菜单，优先找这些选项：
   - `Show Create Table`
   - `DDL`
   - `Generate SQL`
   - `Open Table`

如果插件界面里没有直接展示 DDL，就在查询窗口执行：

```sql
SHOW CREATE TABLE equipments;
SHOW CREATE TABLE borrowrecords;
```

### 看存储过程源码

1. 展开 `<database_name> -> Procedures`
2. 点击 `sp_sync_equipment_status`
3. 点击 `sp_batch_transfer_available_equipment`
4. 如果插件支持，会直接显示过程定义

如果插件里点开后看不到源码，就在查询窗口执行：

```sql
SHOW CREATE PROCEDURE sp_sync_equipment_status;
SHOW CREATE PROCEDURE sp_batch_transfer_available_equipment;
```

### 看索引

在查询窗口执行：

```sql
SHOW INDEX FROM equipments;
SHOW INDEX FROM borrowrecords;
```

如果要看 benchmark 表上的索引：

```sql
SHOW INDEX FROM benchmark_equipments;
SHOW INDEX FROM benchmark_borrowrecords;
```

## 2. 我生成的基准测试数据

为了更清楚地比较索引前后性能，我另外建立了两张专门测试用的表：

- `benchmark_equipments`：50000 行
- `benchmark_borrowrecords`：200000 行

对应脚本：

- `06_benchmark_setup.sql`
- `07_benchmark_queries.sql`

## 3. 索引前后对比结果

### 查询 1

```sql
SELECT SQL_NO_CACHE equip_id, equip_name, status
FROM benchmark_equipments
WHERE category_id = 3
  AND status = 'Available';
```

#### 建索引前

- 执行计划：`Table scan on benchmark_equipments`
- `EXPLAIN ANALYZE` 关键时间：扫描 50000 行，约 `11.5 ms`
- 实测 5 次平均耗时：`137.009 ms`

#### 建索引后

建立索引：

```sql
CREATE INDEX idx_bm_equipments_category_status
ON benchmark_equipments (category_id, status);
```

- 执行计划：`Index lookup using idx_bm_equipments_category_status`
- `EXPLAIN ANALYZE` 关键时间：约 `8.14 ms`
- 实测 5 次平均耗时：`128.119 ms`

#### 结论

这个查询返回结果较多，一次会返回 `7573` 行，所以虽然执行计划已经从“全表扫描”优化为“复合索引查找”，但总耗时提升不算特别夸张。原因是大量结果返回本身也要花时间。

### 查询 2

```sql
SELECT SQL_NO_CACHE record_id, user_id, equip_id, borrow_date
FROM benchmark_borrowrecords
WHERE user_id = 42
ORDER BY borrow_date DESC
LIMIT 10;
```

#### 建索引前

- 执行计划：`Table scan` + `Sort`
- `EXPLAIN ANALYZE` 关键时间：扫描 200000 行，约 `38.6 ms`
- 实测 5 次平均耗时：`55.856 ms`

#### 建索引后

建立索引：

```sql
CREATE INDEX idx_bm_borrowrecords_user_borrow_date
ON benchmark_borrowrecords (user_id, borrow_date DESC);
```

- 执行计划：直接 `Index lookup using idx_bm_borrowrecords_user_borrow_date`
- `EXPLAIN ANALYZE` 关键时间：约 `0.13 ms`
- 实测 5 次平均耗时：`33.528 ms`

#### 结论

这个查询的优化效果很明显，因为复合索引同时满足了：

- `WHERE user_id = 42`
- `ORDER BY borrow_date DESC`
- `LIMIT 10`

所以不再需要全表扫描和额外排序。

## 4. 可以直接写进报告的总结

在实验室设备管理系统中，针对高频查询建立二级索引后，查询性能得到明显改善。

1. 对 `benchmark_equipments(category_id, status)` 建立复合索引后，查询由全表扫描变为索引查找，执行计划得到优化。
2. 对 `benchmark_borrowrecords(user_id, borrow_date DESC)` 建立复合索引后，查询由“全表扫描 + 排序”优化为直接使用索引返回结果，性能提升更明显。
3. 当查询返回结果集较大时，索引虽然能减少扫描成本，但整体耗时还会受到结果传输影响；当查询条件选择性较好且存在排序需求时，索引优化效果最显著。
