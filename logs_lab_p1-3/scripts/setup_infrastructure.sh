#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "Ошибка: запустите скрипт от имени root (через sudo)"
    exit 1
fi

IMAGE_FILE="/logs_disk.img"
MOUNT_DIR="/LOGS"


if [ ! -f "$IMAGE_FILE" ]; then
    echo "1. Файл-образ не найден. Создаем файл размером 100 МБ..."
    dd if=/dev/zero of="$IMAGE_FILE" bs=1M count=100 status=none
    
    echo "2. Форматируем в ext4..."
    mkfs.ext4 -F "$IMAGE_FILE" > /dev/null
else
    echo "1. Файл-образ $IMAGE_FILE уже существует. Пропускаем создание и форматирование (данные сохранены)."
fi

echo "3. Создаем точку монтирования $MOUNT_DIR..."
mkdir -p "$MOUNT_DIR"

echo "4. Прописываем в /etc/fstab для автозагрузки..."
if ! grep -q "$IMAGE_FILE" /etc/fstab; then
    echo "$IMAGE_FILE $MOUNT_DIR ext4 loop,defaults 0 0" >> /etc/fstab
fi

echo "5. Монтируем..."
if ! mount -a; then
    echo "Ошибка: не удалось смонтировать файловые системы"
    exit 1
fi

if ! mountpoint -q "$MOUNT_DIR"; then
    echo "Ошибка: $MOUNT_DIR не является точкой монтирования"
    exit 1
fi

echo "6. Создаем папки для сервисов..."
mkdir -p "$MOUNT_DIR/auth_service" "$MOUNT_DIR/data_process_service" "$MOUNT_DIR/system_event_handler_service"

echo "Готово!"
