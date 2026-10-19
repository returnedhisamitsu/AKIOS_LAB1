s#!/bin/bash


MOUNT_POINT="/LOGS"
DISK_IMAGE="/logs_disk.img"

if ! mountpoint -q "$MOUNT_POINT"; then
    echo "Раздел $MOUNT_POINT не смонтирован. Пытаемся смонтировать..."
    if [ -f "$DISK_IMAGE" ]; then
        mount "$MOUNT_POINT"
        logger "Раздел /LOGS был успешно смонтирован скриптом"
        echo "Успешно смонтировано."
    else
        echo "Ошибка: Файл-образ $DISK_IMAGE не найден!"
        exit 1
    fi
else
    echo "Раздел $MOUNT_POINT уже смонтирован."
fi
