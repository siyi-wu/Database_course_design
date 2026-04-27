# 当前配置的 MySQL 数据库 实例限制说明

## 结论

当前实例虽然返回的版本号是 `MySQL 8.0.36`，但新建表会被强制创建为 `DUCKDB` 引擎，而不是标准课程作业常用的 `InnoDB`。因此你负责的以下要求无法在这台实例上完整验证：

- 表间外键参照关系
- 二级索引创建与性能对比
- 一部分依赖标准 MySQL 行为的游标过程

## 已核实的证据

执行 `SHOW ENGINES` 可以看到同时存在 `DUCKDB` 和 `InnoDB`，但即使显式写 `ENGINE=InnoDB`，最终建表结果仍然是 `DUCKDB`。

测试语句：

```sql
CREATE TABLE engine_test (id INT PRIMARY KEY) ENGINE=InnoDB;
SHOW CREATE TABLE engine_test;
```

返回结果中的核心信息：

```sql
ENGINE=DUCKDB
```

对当前业务表执行检查：

```sql
SELECT table_name, engine
FROM information_schema.tables
WHERE table_schema = '<database_name>';
```

结果显示 5 张业务表全部为 `DUCKDB`。

继续检查外键：

```sql
SELECT table_name, constraint_name, referenced_table_name
FROM information_schema.referential_constraints
WHERE constraint_schema = '<database_name>';
```

结果为空，说明外键没有真正建立成功。

## 对作业的影响

1. `ENGINE=InnoDB` 会被忽略，因此无法依靠该实例完成“表之间要存在参照关系”的真实落库验证。
2. 显式创建的复合索引没有正常体现在 `SHOW INDEX` 结果里，也无法得到符合预期的索引优化效果。
3. 游标过程中如果使用 `CREATE TEMPORARY TABLE ... AS SELECT ...`，会直接报错：

```text
[DuckDB] Does not support duckdb engine in CREATE TABLE ... SELECT statement.
```

## 建议

为了顺利完成课程要求，建议改用一套标准 `InnoDB` 的 MySQL 环境再执行本目录中的 SQL 文件。可选方案：

- 新建一个普通 MySQL 8.0 实例，确认默认存储引擎为 `InnoDB`
- 改到本地 MySQL / XAMPP / Docker MySQL 中完成最终演示

## 已准备好的可迁移内容

即使当前 RDS 受限，本目录中以下内容已经按标准 MySQL 作业要求整理好，可直接迁移到正常的 MySQL 环境：

- `01_schema_and_seed.sql`
- `02_cursor_procedures.sql`
- `03_index_analysis.sql`
- `04_normalization_design.md`
