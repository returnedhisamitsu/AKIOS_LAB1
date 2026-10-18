#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "Ошибка: запустите скрипт от имени root (через sudo)"
    exit 1
fi

IMAGE_FILE="/logs_disk.img"
MOUNT_DIR="/LOGS"

echo "1. Создаем файл-образ размером 100 МБ..."
dd if=/dev/zero of="$IMAGE_FILE" bs=1M count=100 status=none

echo "2. Форматируем в ext4..."
mkfs.ext4 -F "$IMAGE_FILE" > /dev/null

echo "3. Создаем точку монтирования $MOUNT_DIR..."
mkdir -p "$MOUNT_DIR"

echo "4. Прописываем в /etc/fstab для автозагрузки..."
if ! grep -q "$IMAGE_FILE" /etc/fstab; then
    echo "$IMAGE_FILE $MOUNT_DIR ext4 loop,defaults 0 0" » /etc/fstab
fi

echo "5. Монтируем..."
mount -a
echo "Готово! Раздел /LOGS смонтирован."
