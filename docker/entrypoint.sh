#!/bin/sh
set -e

DB_HOST="${DB_HOST:-mysql}"
DB_PORT="${DB_PORT:-3306}"
DB_USER="${DB_USER:?DB_USER is required}"
DB_PASS="${DB_PASS:?DB_PASS is required}"
DB_NAME="${DB_NAME:-epay}"
DB_PREFIX="${DB_PREFIX:-pay}"

echo "[Epay] Waiting for MySQL at $DB_HOST:$DB_PORT ..."
until mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" -e "SELECT 1" > /dev/null 2>&1; do
    sleep 2
done
echo "[Epay] MySQL is ready."

	# 写入 config.php
	cat > /var/www/html/config.php <<EOF
<?php
\$dbconfig = array(
    'host'   => '${DB_HOST}',
    'port'   => ${DB_PORT},
    'user'   => '${DB_USER}',
    'pwd'    => '${DB_PASS}',
    'dbname' => '${DB_NAME}',
    'dbqz'   => '${DB_PREFIX}'
);
EOF

	# Ensure MySQL client defaults to UTF-8 for import / queries executed here
	mysql --default-character-set=utf8mb4 -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" \
		-e "SET NAMES utf8mb4;" >/dev/null 2>&1 || true

	# 初始化数据库（只在首次运行时执行）
TABLE_COUNT=$(mysql --default-character-set=utf8mb4 -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" \
    -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${DB_NAME}';" \
    --skip-column-names 2>/dev/null || echo "0")

if [ "$TABLE_COUNT" -eq "0" ]; then
    echo "[Epay] Initializing database..."
    # 替换表前缀
    sed "s/pre_/${DB_PREFIX}_/g" /var/www/html/install/install.sql | \
        mysql --default-character-set=utf8mb4 -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME"
    echo "[Epay] Database initialized. Set a strong admin password before exposing /admin/. No merchant accounts are created by default; register one at /user/reg.php"
else
    echo "[Epay] Database already initialized, skipping."
fi

# 安装保护：创建 install.lock，避免站点被判定为未安装/可重装
if [ -f /var/www/html/install/index.php ] && [ ! -f /var/www/html/install/install.lock ]; then
    echo "[Epay] Creating install/install.lock"
    mkdir -p /var/www/html/install
    : > /var/www/html/install/install.lock
fi

echo "[Epay] Starting services..."
exec /usr/bin/supervisord -c /etc/supervisord.conf
