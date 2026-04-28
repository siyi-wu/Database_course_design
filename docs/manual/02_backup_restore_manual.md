# 数据库备份与恢复手册

本项目的数据集中保存在 MySQL 数据库 `<database_name>` 中。为了满足课程设计中“数据备份与恢复机制”的评分要求，项目提供了基于 `mysqldump` 和 `mysql` 命令的逻辑备份与恢复方案。

## 1. 备份方式

执行：

```bash
scripts/backup_database.sh
```

脚本会读取根目录 `config.txt` 中的数据库主机、端口、用户名和数据库名，并在执行时提示输入数据库密码。默认备份文件会生成到：

```text
backups/<database_name>_时间戳.sql
```

也可以指定输出文件：

```bash
scripts/backup_database.sh backups/<database_name>_demo.sql
```

## 2. 恢复方式

执行：

```bash
scripts/restore_database.sh backups/<database_name>_demo.sql
```

恢复脚本会在执行前要求输入 `YES` 确认，避免误恢复覆盖数据。

## 3. 备份内容说明

备份脚本使用以下参数：

- `--single-transaction`：在 InnoDB 下进行一致性逻辑备份，减少对业务表的锁定影响。
- `--routines`：备份存储过程和函数。
- `--triggers`：备份触发器。
- `--events`：备份事件对象。

因此备份文件不仅包含表结构和数据，也包含本项目使用的触发器、存储过程、函数等数据库对象。

## 4. 数据库部署说明

如果部署环境提供自动备份、快照或恢复能力，也可以与本项目的逻辑备份脚本配合使用。课程验收时可以说明：本项目既提供 MySQL 标准逻辑备份脚本，也能适配不同部署环境的备份恢复方案。
