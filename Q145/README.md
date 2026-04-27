# 实验室设备管理系统作业文件

本目录对应你负责的内容：`1. 表及参照关系`、`4. 两个使用游标的存储过程`、`5. 二级索引与性能分析`。

文件说明：

- `01_schema_and_seed.sql`：重建 5 张表、补齐外键，并生成演示数据
- `02_cursor_procedures.sql`：两个使用游标操作数据表的存储过程
- `03_index_analysis.sql`：索引创建与 `EXPLAIN` 分析脚本
- `04_normalization_design.md`：规范化设计说明，可直接整理进报告
- `05_rds_limitations.md`：当前配置的 MySQL 数据库 无法完整验证作业要求的原因说明

建议执行顺序：

1. `01_schema_and_seed.sql`
2. `02_cursor_procedures.sql`
3. `CALL sp_sync_equipment_status();`
4. `03_index_analysis.sql`

注意：

本目录中的 SQL 按标准 `MySQL 8.0 + InnoDB` 编写。你当前提供的阿里云实例会把新表强制落成 `DUCKDB` 引擎，导致外键、复合索引和部分游标过程无法按课程要求真实验证，详见 `05_rds_limitations.md`。