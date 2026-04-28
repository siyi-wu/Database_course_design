# 实验室设备管理系统数据库课程设计

本仓库是数据库课程设计项目，系统主题为“实验室设备管理系统”。目录已按正常数据库项目的构建方式组织，不再按个人题号分组。

## 目录结构

- `docs/course/`：课程要求与实施说明。
- `docs/analysis/`：需求分析与 ER 模型。
- `docs/design/`：系统设计说明与规范化过程。
- `docs/manual/`：操作手册。
- `docs/testing/`：测试报告、运行结果与性能测试记录。
- `docs/course_design_full_report.md`：课程设计总文档入口。
- `docs/implementation_notes/`：实现说明归档。
- `sql/01_schema/`：建表、外键与初始化数据脚本。
- `sql/02_programmability/`：游标存储过程、触发器、带参存储过程和函数。
- `sql/03_indexes/`：索引设计与查询分析脚本。
- `sql/04_benchmark/`：索引性能测试数据与查询脚本。
- `sql/05_demo/`：演示与验收测试脚本。
- `sql/06_admin/`：数据库安全授权脚本。
- `scripts/`：数据库备份与恢复脚本。

## SQL 执行顺序

1. `sql/01_schema/01_schema_and_seed.sql`
2. `sql/02_programmability/01_cursor_procedures.sql`
3. `sql/02_programmability/02_triggers.sql`
4. `sql/02_programmability/03_parameterized_routines.sql`
5. `sql/02_programmability/04_views.sql`
6. `sql/02_programmability/05_transaction_demo.sql`
7. `sql/03_indexes/01_index_analysis.sql`
8. `sql/04_benchmark/01_benchmark_setup.sql`
9. `sql/04_benchmark/02_benchmark_queries.sql`
10. `sql/05_demo/01_demo_and_test.sql`
11. `sql/06_admin/01_security_setup.sql`（部署时替换密码后执行）

## 课程要求对应关系

- 至少 5 张表与参照关系：`sql/01_schema/01_schema_and_seed.sql`
- 至少 3 个触发器：`sql/02_programmability/02_triggers.sql`
- 至少 2 个带参存储过程或函数：`sql/02_programmability/03_parameterized_routines.sql`
- 至少 2 个使用游标的存储过程：`sql/02_programmability/01_cursor_procedures.sql`
- 视图与复杂查询封装：`sql/02_programmability/04_views.sql`
- 事务处理与并发控制演示：`sql/02_programmability/05_transaction_demo.sql`
- 至少 2 个二级索引及性能分析：`sql/03_indexes/`、`sql/04_benchmark/`、`docs/testing/03_benchmark_results.md`
- 数据库安全设置：`sql/06_admin/01_security_setup.sql`
- 数据备份与恢复：`scripts/backup_database.sh`、`scripts/restore_database.sh`、`docs/manual/02_backup_restore_manual.md`
- 规范化理论建模过程：`docs/design/02_normalization_design_part_1_4_5.md`、`docs/design/03_normalization_process_part_2_3_6.md`

## 说明

项目已补充 UI 界面、视图、事务并发演示、安全授权模板、备份恢复脚本和测试文档，可按 `演示操作流程.md` 进行课程验收演示。
