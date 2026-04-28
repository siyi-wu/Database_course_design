#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="${ROOT_DIR}/config.txt"
SKIP_BENCHMARK=0
RUN_SECURITY=0
ASSUME_YES=0

usage() {
  cat <<'USAGE'
用法：scripts/init_database.sh [选项]

选项：
  --yes              跳过清库确认，直接重建数据库
  --skip-benchmark   跳过 benchmark 大数据与性能查询脚本，加快初始化
  --with-security    额外执行 sql/06_admin/01_security_setup.sql
  -h, --help         显示帮助

说明：
  脚本会读取根目录 config.txt，DROP 并重新 CREATE 配置中的 database，
  然后按项目依赖顺序导入建表、数据、触发器、存储过程、视图、索引和演示 SQL。
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --yes)
      ASSUME_YES=1
      ;;
    --skip-benchmark)
      SKIP_BENCHMARK=1
      ;;
    --with-security)
      RUN_SECURITY=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "未知选项：$1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

pick() {
  local key="$1"
  awk -v key="$key" '
    BEGIN { FS = ":" }
    tolower($1) == tolower(key) {
      value = substr($0, index($0, ":") + 1)
      sub(/^[ \t]+/, "", value)
      sub(/[ \t\r]+$/, "", value)
      print value
      exit
    }
  ' "$CONFIG_FILE"
}

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "找不到配置文件：$CONFIG_FILE" >&2
  exit 1
fi

DB_HOST="${DB_HOST:-$(pick host)}"
DB_PORT="${DB_PORT:-$(pick port)}"
DB_USER="${DB_USER:-$(pick username)}"
DB_PASSWORD="${DB_PASSWORD:-$(pick password)}"
DB_NAME="${DB_NAME:-$(pick database)}"

if [[ -z "$DB_HOST" || -z "$DB_PORT" || -z "$DB_USER" || -z "$DB_PASSWORD" || -z "$DB_NAME" ]]; then
  echo "config.txt 缺少 host、port、username、password 或 database 配置" >&2
  exit 1
fi

if [[ ! "$DB_NAME" =~ ^[A-Za-z0-9_]+$ ]]; then
  echo "数据库名只能包含字母、数字和下划线：$DB_NAME" >&2
  exit 1
fi

MYSQL_DEFAULTS="$(mktemp)"
trap 'rm -f "$MYSQL_DEFAULTS"' EXIT
chmod 600 "$MYSQL_DEFAULTS"
cat > "$MYSQL_DEFAULTS" <<EOF
[client]
host=${DB_HOST}
port=${DB_PORT}
user=${DB_USER}
password=${DB_PASSWORD}
default-character-set=utf8mb4
EOF

MYSQL=(mysql --defaults-extra-file="$MYSQL_DEFAULTS" --protocol=TCP)

echo "目标数据库：${DB_USER}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
echo "警告：该操作会 DROP DATABASE ${DB_NAME} 并重新初始化。"

if [[ "$ASSUME_YES" -ne 1 ]]; then
  read -r -p "确认继续？输入 YES： " confirm
  if [[ "$confirm" != "YES" ]]; then
    echo "已取消初始化"
    exit 0
  fi
fi

echo "1/4 重建数据库 ${DB_NAME}"
"${MYSQL[@]}" -e "DROP DATABASE IF EXISTS \`${DB_NAME}\`; CREATE DATABASE \`${DB_NAME}\` DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE utf8mb4_unicode_ci;"

run_sql() {
  local label="$1"
  local file="$2"
  echo "执行：${label}"
  "${MYSQL[@]}" "$DB_NAME" < "${ROOT_DIR}/${file}"
}

echo "2/4 导入核心结构、数据和数据库对象"
run_sql "建表与初始化数据" "sql/01_schema/01_schema_and_seed.sql"
run_sql "游标存储过程" "sql/02_programmability/01_cursor_procedures.sql"
run_sql "触发器" "sql/02_programmability/02_triggers.sql"
run_sql "带参存储过程和函数" "sql/02_programmability/03_parameterized_routines.sql"
run_sql "视图" "sql/02_programmability/04_views.sql"
run_sql "事务过程" "sql/02_programmability/05_transaction_demo.sql"
run_sql "索引与 EXPLAIN" "sql/03_indexes/01_index_analysis.sql"

if [[ "$SKIP_BENCHMARK" -eq 1 ]]; then
  echo "3/4 已跳过 benchmark 大数据与性能查询脚本"
else
  echo "3/4 导入 benchmark 数据并执行性能查询"
  run_sql "benchmark 数据" "sql/04_benchmark/01_benchmark_setup.sql"
  run_sql "benchmark 查询" "sql/04_benchmark/02_benchmark_queries.sql"
fi

echo "4/4 执行演示验证 SQL"
run_sql "演示与验收测试" "sql/05_demo/01_demo_and_test.sql"

if [[ "$RUN_SECURITY" -eq 1 ]]; then
  run_sql "安全授权模板" "sql/06_admin/01_security_setup.sql"
else
  echo "安全授权脚本默认不执行。如需执行，请添加 --with-security。"
fi

echo "初始化完成。快速统计："
"${MYSQL[@]}" "$DB_NAME" -e "
SELECT 'categories' AS table_name, COUNT(*) AS row_count FROM categories
UNION ALL SELECT 'labrooms', COUNT(*) FROM labrooms
UNION ALL SELECT 'users', COUNT(*) FROM users
UNION ALL SELECT 'equipments', COUNT(*) FROM equipments
UNION ALL SELECT 'borrowrecords', COUNT(*) FROM borrowrecords;
SHOW TRIGGERS;
SHOW PROCEDURE STATUS WHERE Db = '${DB_NAME}';
"
