# 实验室设备管理系统课程设计总文档

## 1. 项目概述

本项目以“实验室设备管理系统”为主题，面向实验室设备台账维护、设备借用、设备归还、设备状态跟踪和借还记录查询等业务场景，设计并实现了基于 MySQL 的数据库系统和配套 UI 界面。

系统使用 MySQL 8.0 / InnoDB 作为数据库，React + Vite 实现前端界面，Express + mysql2 实现后端接口。核心业务规则通过数据库主键、外键、触发器、存储过程、函数、视图、索引和事务演示过程实现。

## 2. 课程要求对应关系

| 课程要求 | 实现内容 | 文件位置 |
| --- | --- | --- |
| 至少 5 张表且存在参照关系 | 设备类别、实验室、用户、设备、借用记录 5 张核心表 | `sql/01_schema/01_schema_and_seed.sql` |
| 至少 3 个触发器 | 借用前校验、借用后状态维护、归还后状态恢复 | `sql/02_programmability/02_triggers.sql` |
| 至少 2 个带参存储过程或函数 | 借用过程、归还过程、用户未归还数量函数 | `sql/02_programmability/03_parameterized_routines.sql` |
| 至少 2 个游标过程 | 批量同步设备状态、批量调拨可用设备 | `sql/02_programmability/01_cursor_procedures.sql` |
| 至少 2 个二级索引和性能分析 | 设备类别状态索引、用户借用日期索引等 | `sql/03_indexes/`、`sql/04_benchmark/`、`docs/testing/03_benchmark_results.md` |
| 规范化理论建模过程 | 从未规范化单据到 3NF | `docs/design/03_normalization_process_part_2_3_6.md` |

## 3. 系统分析

需求分析文档位于：

```text
docs/analysis/01_requirement_analysis.md
```

ER 模型文档位于：

```text
docs/analysis/02_er_model.md
```

系统包含 5 个核心实体：

- 设备类别 `categories`
- 实验室房间 `labrooms`
- 用户 `users`
- 设备 `equipments`
- 借用记录 `borrowrecords`

实体之间形成类别到设备、房间到设备、用户到借用记录、设备到借用记录的 1:n 联系。

## 4. 系统设计

系统设计说明书位于：

```text
docs/design/01_system_design.md
```

数据库对象包括：

- 表和外键
- 游标存储过程
- 触发器
- 带参存储过程和函数
- 视图
- 二级索引
- 事务演示过程
- 安全授权模板
- 备份恢复脚本

UI 采用前后端分离结构：

- 前端：`ui/src/main.jsx`
- 后端：`ui/server/index.js`
- 数据库脚本：`sql/`

## 5. 数据库实现

SQL 执行顺序见根目录：

```text
README.md
```

核心 SQL 文件：

- `sql/01_schema/01_schema_and_seed.sql`
- `sql/02_programmability/01_cursor_procedures.sql`
- `sql/02_programmability/02_triggers.sql`
- `sql/02_programmability/03_parameterized_routines.sql`
- `sql/02_programmability/04_views.sql`
- `sql/02_programmability/05_transaction_demo.sql`
- `sql/03_indexes/01_index_analysis.sql`
- `sql/04_benchmark/01_benchmark_setup.sql`
- `sql/04_benchmark/02_benchmark_queries.sql`
- `sql/05_demo/01_demo_and_test.sql`
- `sql/06_admin/01_security_setup.sql`

## 6. UI 实现

UI 位于：

```text
ui/
```

主要功能：

- 总览统计
- 设备管理
- 用户管理
- 实验室房间管理
- 设备类别管理
- 设备借用
- 设备归还
- 借用记录查询

启动方式：

```bash
cd ui
npm install
npm run dev
```

访问地址：

```text
http://localhost:5173/
```

## 7. 测试与验证

测试材料位于：

```text
docs/testing/
```

主要测试文档：

- `docs/testing/01_test_report.md`
- `docs/testing/03_benchmark_results.md`
- `docs/testing/04_cloud_run_results_part_2_3_6.md`
- `docs/testing/05_ui_test_report.md`
- `docs/testing/06_transaction_concurrency_test.md`

测试覆盖：

- 借用成功
- 归还成功
- 重复借出失败
- 用户未归还数量统计
- 配置的 MySQL 数据库对象创建
- 索引性能分析
- UI 功能测试
- 事务并发控制说明

## 8. 操作手册

操作说明位于：

```text
docs/manual/
```

包括：

- `docs/manual/01_operation_manual.md`
- `docs/manual/02_backup_restore_manual.md`

## 9. 演示流程

答辩或验收时建议直接按照根目录文档进行：

```text
演示操作流程.md
```

该文档已经按课程要求和评分标准组织了完整演示顺序。

## 10. 总结

本项目完成了数据库课程设计要求中的建表、参照完整性、触发器、带参存储过程或函数、游标、索引性能分析和规范化过程，并补充了 UI 界面、视图、事务并发演示、安全授权模板、备份恢复脚本和完整测试文档。

系统不仅能够保存实验室设备管理数据，也能够通过数据库对象主动维护借还业务一致性，并通过 UI 直观展示数据库系统的实际使用过程。
