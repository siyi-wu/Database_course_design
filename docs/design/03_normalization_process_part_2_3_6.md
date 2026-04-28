# 实验室设备管理系统规范化建模过程

## 1. 业务背景

实验室设备管理系统需要记录设备基本信息、设备所属类别、设备所在实验室、借用用户以及借还流水。系统既要支持日常设备查询，也要支持借出、归还、状态维护和统计分析。

如果直接把所有信息放在一张表中，虽然短期实现简单，但会造成大量冗余和维护风险。因此本系统采用规范化理论，从未规范化业务单据逐步分解到第三范式。

## 2. 未规范化原始业务单据

原始借用登记单可以抽象为：

`设备编号, 设备名称, 设备类别名称, 类别说明, 房间名称, 房间位置, 房间管理员, 设备状态, 设备价格, 购置日期, 借用人编号, 借用人姓名, 借用人角色, 借用人联系方式, 借用日期, 计划归还日期, 实际归还日期`

该结构存在以下问题：

- 同一设备类别会在多台设备中重复出现。
- 同一实验室房间、位置和管理员会在多台设备中重复出现。
- 同一用户的姓名、角色和联系方式会在多条借用记录中重复出现。
- 如果设备从未被借用，借用人和借用日期字段为空，不利于表达设备台账。
- 删除某条借用记录时，可能误删用户、设备、类别或房间信息。

## 3. 主要函数依赖

根据业务含义，可得到主要函数依赖：

- `category_id -> category_name, description`
- `room_id -> room_name, location, admin_name`
- `user_id -> user_name, role, contact`
- `equip_id -> equip_name, category_id, room_id, status, price, purchase_date`
- `record_id -> equip_id, user_id, borrow_date, plan_return_date, actual_return_date`

如果使用原始大表，还会存在传递依赖：

- `equip_id -> category_id -> category_name, description`
- `equip_id -> room_id -> room_name, location, admin_name`
- `record_id -> user_id -> user_name, role, contact`

这些传递依赖是后续分解的主要依据。

## 4. 第一范式 1NF

第一范式要求属性值不可再分，表中不能出现重复组。本系统将复合信息拆成原子字段：

- 房间信息拆成 `room_name`、`location`、`admin_name`。
- 用户信息拆成 `user_name`、`role`、`contact`。
- 借还时间拆成 `borrow_date`、`plan_return_date`、`actual_return_date`。
- 设备属性拆成 `equip_name`、`status`、`price`、`purchase_date`。

经过 1NF 处理后，每个字段都只保存一个含义明确的原子值。

## 5. 第二范式 2NF

第二范式要求在满足 1NF 的基础上，非主属性必须完全依赖于候选键，不能只依赖复合键的一部分。

在原始借用明细表中，如果使用类似 `(equip_id, record_id)` 或 `(equip_id, user_id, borrow_date)` 作为组合标识，那么设备名称、类别、房间等属性只依赖设备编号，用户姓名和联系方式只依赖用户编号，存在部分依赖。

为消除部分依赖，系统将主数据和业务记录拆分：

- 设备类别独立为 `categories`。
- 实验室房间独立为 `labrooms`。
- 用户独立为 `users`。
- 设备台账独立为 `equipments`。
- 借用流水独立为 `borrowrecords`。

拆分后每张表都使用单字段主键，非主属性完整依赖本表主键，因此满足 2NF。

## 6. 第三范式 3NF

第三范式要求在满足 2NF 的基础上，不存在非主属性对主键的传递依赖。

系统通过以下方式消除传递依赖：

- `equipments` 中只保存 `category_id`，不重复保存 `category_name` 和 `description`。
- `equipments` 中只保存 `room_id`，不重复保存 `room_name`、`location` 和 `admin_name`。
- `borrowrecords` 中只保存 `user_id`，不重复保存 `user_name`、`role` 和 `contact`。
- `borrowrecords` 中只保存 `equip_id`，不重复保存设备名称、类别和房间。

这样，每个非主属性都直接依赖本表主键，而不是依赖另一个非主属性，最终模式达到 3NF。

## 7. 最终关系模式

### categories

`categories(category_id, category_name, description)`

- 主键：`category_id`
- 唯一约束：`category_name`
- 说明：保存设备类别主数据。

### labrooms

`labrooms(room_id, room_name, location, admin_name)`

- 主键：`room_id`
- 唯一约束：`room_name`
- 说明：保存实验室房间主数据。

### users

`users(user_id, user_name, role, contact)`

- 主键：`user_id`
- 说明：保存借用人信息。

### equipments

`equipments(equip_id, equip_name, category_id, room_id, status, price, purchase_date)`

- 主键：`equip_id`
- 外键：`category_id` 引用 `categories(category_id)`
- 外键：`room_id` 引用 `labrooms(room_id)`
- 说明：保存设备台账。

### borrowrecords

`borrowrecords(record_id, equip_id, user_id, borrow_date, plan_return_date, actual_return_date)`

- 主键：`record_id`
- 外键：`equip_id` 引用 `equipments(equip_id)`
- 外键：`user_id` 引用 `users(user_id)`
- 说明：保存设备借还流水。

## 8. 完整性约束

系统使用多种约束保证数据质量：

- 实体完整性：每张表都有主键，保证行唯一。
- 参照完整性：设备必须引用有效类别和房间，借用记录必须引用有效设备和用户。
- 用户定义完整性：设备状态使用枚举值 `Available`、`Borrowed`、`Maintenance`、`Scrapped`。
- 业务完整性：通过触发器阻止维修或报废设备借出，阻止设备重复借出，自动维护设备状态。

## 9. 规范化收益

规范化后的数据库具有以下优点：

- 降低冗余，类别、房间、用户信息只保存一份。
- 避免更新异常，修改用户联系方式或房间管理员时只需更新主数据表。
- 避免插入异常，可以先录入设备、用户和房间，不要求必须有借用记录。
- 避免删除异常，删除借用流水不会删除设备、用户、类别和房间主数据。
- 方便扩展触发器、存储过程、索引和统计查询。

## 10. 规范化权衡

规范化会增加多表连接查询的数量，例如查询完整借用明细时需要连接 `borrowrecords`、`equipments`、`users`、`categories` 和 `labrooms`。但该成本可以通过二级索引、视图或应用层查询封装降低。对于本系统的数据一致性和课程设计要求而言，达到 3NF 是更合理的选择。
