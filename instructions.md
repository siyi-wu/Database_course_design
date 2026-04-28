# 数据库课程设计实施说明

## 1. 对题目要求的总体认识

本次数据库课程设计要求以一个现实生活中的信息管理系统为背景，完成数据库建模、初始化 SQL、基本增删改查、高级数据库对象、系统分析文档、系统设计文档和个人报告等内容。题目中的核心数据库要求共有 6 项：

1. 系统至少由 5 张表组成，且表之间存在参照关系。
2. 至少包含 3 个触发器。
3. 至少包含 2 个带参存储过程或函数。
4. 至少有 2 个使用游标对数据库中的表进行操作的存储过程。
5. 至少建立 2 个二级索引，并完成相关查询性能分析。
6. 描述应用规范化理论建立模式的详细过程。

本组选定的系统主题是“实验室设备管理系统”。该系统用于管理实验室设备类别、实验室房间、用户、设备台账和设备借还记录，适合作为数据库课程设计案例，因为它天然包含主数据、业务记录、外键参照、状态维护、统计查询、触发器、存储过程、索引优化和规范化分析等内容。

## 2. Q145 已完成内容的认识

另一位同学已经完成题目数据库要求中的 `(1)(4)(5)`，代码位于 `Q145` 目录，并且已经在阿里云 MySQL RDS 数据库 `<database_name>` 中运行验证。`Q145` 是本项目后续实现的基础，不能重复重建一套不兼容的表结构。

### 2.1 数据表与参照关系

`Q145/01_schema_and_seed.sql` 建立了 5 张核心表：

- `categories`：设备类别表，主键 `category_id`，唯一约束 `category_name`。
- `labrooms`：实验室房间表，主键 `room_id`，唯一约束 `room_name`。
- `users`：用户表，主键 `user_id`，包含用户姓名、角色和联系方式。
- `equipments`：设备表，主键 `equip_id`，通过 `category_id` 引用 `categories`，通过 `room_id` 引用 `labrooms`。
- `borrowrecords`：借用记录表，主键 `record_id`，通过 `equip_id` 引用 `equipments`，通过 `user_id` 引用 `users`。

表之间的联系包括：

- `categories 1:n equipments`
- `labrooms 1:n equipments`
- `users 1:n borrowrecords`
- `equipments 1:n borrowrecords`

该部分已经满足题目 `(1)` 中“至少 5 张表且存在参照关系”的要求。脚本还使用递归 CTE 生成了演示数据，包括类别、房间、用户、设备和借用记录。

### 2.2 游标存储过程

`Q145/02_cursor_procedures.sql` 已经实现 2 个使用游标的存储过程，满足题目 `(4)`：

- `sp_sync_equipment_status()`：逐台扫描设备，根据未归还借用记录同步设备状态。
- `sp_batch_transfer_available_equipment(p_from_room_id, p_to_room_id, p_limit)`：使用游标逐台调拨指定实验室中的可用设备。

这两个过程都使用了 `CURSOR`、循环、`FETCH` 和 `CONTINUE HANDLER`，符合“使用游标对数据库中的表进行操作”的要求。

### 2.3 索引与性能分析

`Q145/03_index_analysis.sql` 已建立多个二级索引：

- `idx_equipments_category_status(category_id, status)`
- `idx_borrowrecords_user_borrow_date(user_id, borrow_date DESC)`
- `idx_borrowrecords_equip_active(equip_id, actual_return_date, plan_return_date)`

`Q145/06_benchmark_setup.sql`、`Q145/07_benchmark_queries.sql` 和 `Q145/08_benchmark_results.md` 进一步构造 benchmark 数据并进行索引前后对比，满足题目 `(5)`。其中最典型的是用户最近借用记录查询，复合索引同时支持筛选、排序和 `LIMIT`，优化效果明显。

### 2.4 Q145 报告生成

`Q145/generate_report.py` 使用 `python-docx` 自动生成个人报告，报告主题为“本人负责内容：1、4、5”。报告内容包括数据表设计、外键参照、游标过程、索引设计、性能测试和结论。它说明了 Q145 的工作已经形成可提交文档。

后续我的部分应与 Q145 的系统主题、表结构、命名风格和报告风格保持一致，不应另起一个系统，也不应破坏已运行的云数据库对象。

## 3. 我的分工与实现目标

我的主要任务是完成题目数据库要求中的 `(2)(3)(6)`，代码与报告放入 `Q236` 目录：

- `(2)` 至少 3 个触发器。
- `(3)` 至少 2 个带参存储过程或函数。
- `(6)` 使用规范化理论建立模式的详细过程。

此外，题目还要求系统需求分析文档、ER 模型、系统设计说明书、程序设计代码、测试报告、操作手册和个人纸质版报告。除 `(2)(3)(6)` 以外的补充材料放入 `Extra` 目录，用于支撑完整大作业文档。

## 4. Q236 设计方案

### 4.1 触发器设计

触发器直接基于 `borrowrecords` 表和 `equipments` 表实现，重点保证设备借还业务的一致性。

计划实现 3 个触发器：

1. `trg_borrowrecords_before_insert`
   - 触发时机：向 `borrowrecords` 插入借用记录前。
   - 作用：校验借用日期和计划归还日期；校验设备不能处于 `Maintenance` 或 `Scrapped`；校验同一设备不能存在未归还记录。
   - 意义：防止非法借用、重复借用和日期错误进入数据库。

2. `trg_borrowrecords_after_insert`
   - 触发时机：向 `borrowrecords` 插入借用记录后。
   - 作用：如果新记录是未归还借用，则自动把对应设备状态改为 `Borrowed`。
   - 意义：让设备状态随借用记录自动变化，减少应用层手工维护。

3. `trg_borrowrecords_after_update`
   - 触发时机：更新 `borrowrecords` 后。
   - 作用：当实际归还日期由空变为非空时，如果该设备不存在其他未归还记录，则自动把设备状态恢复为 `Available`。
   - 意义：让归还操作自动释放设备，保持设备台账和借还记录一致。

### 4.2 带参存储过程或函数设计

计划实现 2 个带参存储过程和 1 个带参函数，其中前两个已经足以满足题目 `(3)`，函数用于增强报告展示。

1. `sp_borrow_equipment(p_equip_id, p_user_id, p_borrow_date, p_days)`
   - 根据设备编号、用户编号、借用日期和借用天数新增借用记录。
   - 过程内部检查参数，插入 `borrowrecords`。
   - 插入后的设备状态由触发器自动维护。

2. `sp_return_equipment(p_record_id, p_return_date)`
   - 根据借用记录编号和归还日期完成归还。
   - 过程内部检查记录存在性、是否重复归还、归还日期是否合法。
   - 更新后的设备状态由触发器自动维护。

3. `fn_user_active_borrow_count(p_user_id)`
   - 返回某个用户当前未归还设备数量。
   - 用于用户借用状态统计，也方便在报告和演示中展示带参函数。

### 4.3 规范化理论说明

虽然 `Q145/04_normalization_design.md` 已经包含规范化说明，但题目 `(6)` 是我的分工，因此 `Q236` 需要提供更详细、更系统的规范化文档。该文档应包括：

- 原始未规范化业务单据。
- 主要函数依赖。
- 1NF、2NF、3NF 的逐步分解过程。
- 最终关系模式。
- 主键、外键、唯一约束说明。
- 规范化后的收益和权衡。

## 5. 云数据库实施步骤

数据库连接信息存放在 `config.txt` 中，类型为 MySQL，目标库为 `<database_name>`。实施时应注意：

1. 不重新执行 `Q145/01_schema_and_seed.sql`，除非明确需要重置全库。
2. 先确认基础表、Q145 过程和索引已经存在。
3. 执行 `Q236/01_triggers.sql` 创建触发器。
4. 执行 `Q236/02_parameterized_routines.sql` 创建带参过程和函数。
5. 执行 `Q236/04_demo_and_test.sql` 做演示测试。
6. 用 `SHOW TRIGGERS`、`SHOW PROCEDURE STATUS`、`SHOW FUNCTION STATUS`、演示查询结果证明对象已经创建并可运行。

## 6. 文件组织计划

`Q236` 目录用于我的核心分工：

- `README.md`：我的分工说明、文件说明和执行顺序。
- `01_triggers.sql`：3 个触发器。
- `02_parameterized_routines.sql`：带参存储过程和函数。
- `03_normalization_process.md`：规范化理论详细过程。
- `04_demo_and_test.sql`：演示和测试脚本。
- `05_cloud_run_results.md`：云数据库运行结果记录。
- `generate_report.py`：生成个人报告的脚本。

`Extra` 目录用于补齐题目中除数据库 `(2)(3)(6)` 外仍需要整理的文档：

- `01_requirement_analysis.md`：系统需求分析。
- `02_er_model.md`：ER 模型文字版和 Mermaid 图。
- `03_system_design.md`：系统设计说明书。
- `04_operation_manual.md`：操作手册。
- `05_test_report.md`：测试报告。

## 7. 推荐最终验收讲解顺序

答辩或验收时可以按以下顺序展示：

1. 说明系统主题：实验室设备管理系统。
2. 展示 Q145 已完成的数据表、外键、游标过程和索引性能分析。
3. 展示我的 Q236 分工：触发器、带参过程/函数、规范化分析。
4. 执行 `CALL sp_borrow_equipment(...)`，说明触发器自动将设备改为 `Borrowed`。
5. 执行 `CALL sp_return_equipment(...)`，说明触发器自动将设备恢复为 `Available`。
6. 执行 `SELECT fn_user_active_borrow_count(...)`，展示带参函数。
7. 打开 `Q236/03_normalization_process.md`，说明从未规范化表到 3NF 的过程。
8. 使用 `Extra` 目录中的需求分析、ER 模型、系统设计、操作手册和测试报告支撑完整大作业文档。
