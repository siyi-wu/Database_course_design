#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="${ROOT_DIR}/config.txt"
BACKUP_FILE="${1:-}"

pick() {
  local key="$1"
  awk -F: -v key="$key" 'tolower($1) == tolower(key) { sub(/^[ \t]+/, "", $2); print $2; exit }' "$CONFIG_FILE"
}

if [[ -z "$BACKUP_FILE" ]]; then
  echo "用法：scripts/restore_database.sh <backup.sql>" >&2
  exit 1
fi

if [[ ! -f "$BACKUP_FILE" ]]; then
  echo "找不到备份文件：$BACKUP_FILE" >&2
  exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "找不到配置文件：$CONFIG_FILE" >&2
  exit 1
fi

DB_HOST="${DB_HOST:-$(pick host)}"
DB_PORT="${DB_PORT:-$(pick port)}"
DB_USER="${DB_USER:-$(pick username)}"
DB_NAME="${DB_NAME:-$(pick database)}"

echo "即将把 ${BACKUP_FILE} 恢复到数据库 ${DB_NAME}"
read -r -p "确认继续？输入 YES： " confirm
if [[ "$confirm" != "YES" ]]; then
  echo "已取消恢复"
  exit 0
fi

mysql \
  -h "$DB_HOST" \
  -P "$DB_PORT" \
  -u "$DB_USER" \
  -p \
  "$DB_NAME" < "$BACKUP_FILE"

echo "恢复完成"
