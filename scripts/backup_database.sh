#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="${ROOT_DIR}/config.txt"
BACKUP_DIR="${BACKUP_DIR:-${ROOT_DIR}/backups}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

pick() {
  local key="$1"
  awk -F: -v key="$key" 'tolower($1) == tolower(key) { sub(/^[ \t]+/, "", $2); print $2; exit }' "$CONFIG_FILE"
}

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "找不到配置文件：$CONFIG_FILE" >&2
  exit 1
fi

DB_HOST="${DB_HOST:-$(pick host)}"
DB_PORT="${DB_PORT:-$(pick port)}"
DB_USER="${DB_USER:-$(pick username)}"
DB_NAME="${DB_NAME:-$(pick database)}"
OUTPUT_FILE="${1:-${BACKUP_DIR}/${DB_NAME}_${TIMESTAMP}.sql}"

mkdir -p "$(dirname "$OUTPUT_FILE")"

echo "正在备份数据库 ${DB_NAME} 到 ${OUTPUT_FILE}"
mysqldump \
  -h "$DB_HOST" \
  -P "$DB_PORT" \
  -u "$DB_USER" \
  -p \
  --single-transaction \
  --routines \
  --triggers \
  --events \
  "$DB_NAME" > "$OUTPUT_FILE"

echo "备份完成：$OUTPUT_FILE"
