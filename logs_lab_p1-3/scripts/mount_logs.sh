#!/bin/bash


MOUNT_POINT="/LOGS"
DISK_IMAGE="/logs_disk.img"

if [ "$EUID" -ne 0 ]; then
    echo "Ошибка: скрипт должен быть запущен от имени root (sudo)"
    exit 1
fi


if [ ! -f "$DISK_IMAGE" ]; then
    echo "Ошибка: Файл-образ $DISK_IMAGE не найден! Сначала запустите setup_infrastructure.sh"
    exit 1
fi


if mountpoint -q "$MOUNT_POINT"; then
    if mount | grep -q "$DISK_IMAGE on $MOUNT_POINT"; then
        echo "Раздел $MOUNT_POINT уже успешно смонтирован из $DISK_IMAGE."
        exit 0
    else
        echo "Внимание: $MOUNT_POINT занят другим устройством. Размонтируем его..."
        umount "$MOUNT_POINT"
    fi
fi


echo "Пытаемся смонтировать $DISK_IMAGE в $MOUNT_POINT..."
mount "$MOUNT_POINT"


if [ $? -eq 0 ]; then
    logger "Раздел /LOGS был успешно смонтирован скриптом"
    echo "Успешно смонтировано."
else
    logger "ОШИБКА: Не удалось смонтировать раздел /LOGS"
    echo "ОШИБКА: Не удалось смонтировать раздел. Проверьте целостность файловой системы."
    exit 1
fi
