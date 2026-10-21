#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "Ошибка: запустите скрипт от имени root (через sudo)"
    exit 1
fi

PROJECT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

echo "1. Делаем скрипты исполняемыми..."
chmod +x "$PROJECT_DIR"/scripts/*.sh
chmod +x "$PROJECT_DIR"/tests/*.sh

echo "2. Копируем скрипты в /usr/local/bin/ (чтобы systemd их видел)..."
cp "$PROJECT_DIR/scripts/mount_logs.sh" /usr/local/bin/
cp "$PROJECT_DIR/scripts/log_cleaner.sh" /usr/local/bin/

echo "3. Копируем systemd-файлы в систему..."
cp "$PROJECT_DIR/systemd/"*.service /etc/systemd/system/
cp "$PROJECT_DIR/systemd/"*.timer /etc/systemd/system/

echo "4. Перезагружаем systemd и включаем службы..."
systemctl daemon-reload


systemctl enable mount-logs.service


systemctl enable --now log-cleanup.timer

echo "5. Разворачиваем диск (создаем образ и настраиваем fstab)..."
"$PROJECT_DIR/scripts/setup_infrastructure.sh"

echo "========================================="
echo "УСТАНОВКА ЗАВЕРШЕНА УСПЕШНО!"
echo "Проверить статус монтирования: df -h | grep LOGS"
echo "Проверить таймер: systemctl list-timers | grep log-cleanup"
echo "========================================="
