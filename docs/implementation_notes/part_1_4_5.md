# 实验室设备管理系统作业文件

本目录对应你负责的内容：`1. 表及参照关系`、`4. 两个使用游标的存储过程`、`5. 二级索引与性能分析`。

文件说明：

- `01_schema_and_seed.sql`：重建 5 张表、补齐外键，并生成演示数据
- `02_cursor_procedures.sql`：两个使用游标操作数据表的存储过程
- `03_index_analysis.sql`：索引创建与 `EXPLAIN` 分析脚本
- `04_normalization_design.md`：规范化设计说明，可直接整理进报告
- `06_benchmark_setup.sql`：大数据量 benchmark 表与测试数据
- `07_benchmark_queries.sql`：benchmark 查询与索引前后对比 SQL
- `08_benchmark_results.md`：VSCode 查看方法与基准测试结果整理

建议执行顺序：

1. `01_schema_and_seed.sql`
2. `02_cursor_procedures.sql`
3. `CALL sp_sync_equipment_status();`
4. `03_index_analysis.sql`
5. `06_benchmark_setup.sql`
6. `07_benchmark_queries.sql`

注意：

本目录中的 SQL 按标准 `MySQL 8.0 + InnoDB` 编写，现已在新的阿里云 MySQL 实例 `<db_host>` 上完成验证，可以作为当前正式作业环境使用。
