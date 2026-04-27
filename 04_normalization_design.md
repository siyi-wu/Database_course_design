# 实验室设备管理系统规范化设计说明

## 1. 业务对象识别

根据实验室设备管理场景，首先抽取出五类核心业务对象：

- 设备类别 `categories`
- 实验室房间 `labrooms`
- 用户 `users`
- 设备 `equipments`
- 借用记录 `borrowrecords`

其中，设备必须属于某一类别并放置在某一实验室；借用记录必须同时关联一个设备和一个借用人。因此表之间天然存在参照关系。

## 2. 从原始业务表到关系模式

如果直接使用一张“大表”记录业务，通常会设计成下面这种未规范化结构：

`(设备编号, 设备名称, 设备类别, 房间名称, 房间位置, 管理员, 借用人, 借用人角色, 联系方式, 借出日期, 计划归还日期, 实际归还日期, 设备状态, 设备价格, 购置日期)`

这种设计会产生以下问题：

- 同一类别名称、房间信息、用户信息会在多条记录中重复存储，冗余较大。
- 修改房间管理员或用户联系方式时，需要更新多条记录，容易出现更新异常。
- 如果某个设备暂时没有借出记录，就无法自然存储“设备本身”信息，存在插入异常。
- 删除最后一条借用记录时，可能把设备、房间、用户等主数据一并丢失，存在删除异常。

## 3. 第一范式 1NF

1NF 要求字段具有原子性，不可再分。拆分后保留的字段均为不可再分的基本属性：

- 房间名称与位置分开存储
- 用户姓名、角色、联系方式分开存储
- 借用日期、计划归还日期、实际归还日期分别单独存储

因此各表字段均满足 1NF。

## 4. 第二范式 2NF

2NF 要求在满足 1NF 的基础上，非主属性完全依赖于主键，不能只依赖复合主键的一部分。

本系统最终每张表都采用单字段主键，因此不存在对复合主键的部分依赖：

- `categories(category_id -> category_name, description)`
- `labrooms(room_id -> room_name, location, admin_name)`
- `users(user_id -> user_name, role, contact)`
- `equipments(equip_id -> equip_name, category_id, room_id, status, price, purchase_date)`
- `borrowrecords(record_id -> equip_id, user_id, borrow_date, plan_return_date, actual_return_date)`

因此模式满足 2NF。

## 5. 第三范式 3NF

3NF 要求在满足 2NF 的基础上，非主属性之间不存在传递依赖。

系统中做了如下拆分来消除传递依赖：

- 不在 `equipments` 中直接保存 `category_name`，而是保存 `category_id`
- 不在 `equipments` 中直接保存 `room_name/location/admin_name`，而是保存 `room_id`
- 不在 `borrowrecords` 中直接保存 `user_name/contact`，而是保存 `user_id`

这样每张表中的非主属性都只直接依赖本表主键，而不依赖其他非主属性，因此系统达到 3NF。

## 6. 最终关系模式与联系

最终得到的关系模式如下：

- `categories(category_id, category_name, description)`
- `labrooms(room_id, room_name, location, admin_name)`
- `users(user_id, user_name, role, contact)`
- `equipments(equip_id, equip_name, category_id, room_id, status, price, purchase_date)`
- `borrowrecords(record_id, equip_id, user_id, borrow_date, plan_return_date, actual_return_date)`

表间联系如下：

- `categories 1 : n equipments`
- `labrooms 1 : n equipments`
- `users 1 : n borrowrecords`
- `equipments 1 : n borrowrecords`

## 7. 规范化收益

采用上述 3NF 设计后，系统具有以下优点：

- 降低数据冗余，类别、房间、用户信息只维护一份
- 减少插入、删除、更新异常
- 通过外键确保借用记录、设备、用户和房间之间的一致性
- 更便于后续增加触发器、存储过程、索引与性能优化
