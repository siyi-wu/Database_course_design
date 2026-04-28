# 实验室设备管理系统数据库课程设计

本仓库是数据库课程设计项目，系统主题为“实验室设备管理系统”。目录已按正常数据库项目的构建方式组织，不再按个人题号分组。

## 目录结构

- `docs/course/`：课程要求与实施说明。
- `docs/analysis/`：需求分析与 ER 模型。
- `docs/design/`：系统设计说明与规范化过程。
- `docs/manual/`：操作手册。
- `docs/testing/`：测试报告、运行结果与性能测试记录。
- `docs/implementation_notes/`：实现说明归档。
- `sql/01_schema/`：建表、外键与初始化数据脚本。
- `sql/02_programmability/`：游标存储过程、触发器、带参存储过程和函数。
- `sql/03_indexes/`：索引设计与查询分析脚本。
- `sql/04_benchmark/`：索引性能测试数据与查询脚本。
- `sql/05_demo/`：演示与验收测试脚本。

## SQL 执行顺序

1. `sql/01_schema/01_schema_and_seed.sql`
2. `sql/02_programmability/01_cursor_procedures.sql`
3. `sql/02_programmability/02_triggers.sql`
4. `sql/02_programmability/03_parameterized_routines.sql`
5. `sql/03_indexes/01_index_analysis.sql`
6. `sql/04_benchmark/01_benchmark_setup.sql`
7. `sql/04_benchmark/02_benchmark_queries.sql`
8. `sql/05_demo/01_demo_and_test.sql`

## 课程要求对应关系

- 至少 5 张表与参照关系：`sql/01_schema/01_schema_and_seed.sql`
- 至少 3 个触发器：`sql/02_programmability/02_triggers.sql`
- 至少 2 个带参存储过程或函数：`sql/02_programmability/03_parameterized_routines.sql`
- 至少 2 个使用游标的存储过程：`sql/02_programmability/01_cursor_procedures.sql`
- 至少 2 个二级索引及性能分析：`sql/03_indexes/`、`sql/04_benchmark/`、`docs/testing/03_benchmark_results.md`
- 规范化理论建模过程：`docs/design/02_normalization_design_part_1_4_5.md`、`docs/design/03_normalization_process_part_2_3_6.md`

## 说明

本次整理只调整项目目录和文件位置，没有修改已有 SQL 代码内容。
