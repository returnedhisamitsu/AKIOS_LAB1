#!/bin/bash

LOG_ROOT="${LOG_ROOT:-/LOGS}"
ARCHIVE_ROOT="${ARCHIVE_ROOT:-/LOGS_ARCHIVE}"
THRESHOLD="${THRESHOLD:-90}"

if ! mountpoint -q "$LOG_ROOT"; then
    echo "Ошибка: $LOG_ROOT не смонтирован"
    exit 1
fi

if ! [[ "$THRESHOLD" =~ ^(100|[1-9][0-9]?)$ ]]; then
    echo "Ошибка: THRESHOLD должен быть числом от 1 до 100"
    exit 1
fi

if ! DF_OUTPUT=$(df -P -B1 "$LOG_ROOT"); then
    echo "Ошибка: не удалось получить информацию о разделе $LOG_ROOT"
    exit 1
fi

USAGE=$(printf '%s\n' "$DF_OUTPUT" | awk 'NR==2 {print $5}')
USAGE="${USAGE%\%}"

TOTAL_SIZE=$(printf '%s\n' "$DF_OUTPUT" | awk 'NR==2 {print $2}')
MAX_FOLDER_SIZE=$((TOTAL_SIZE / 3))

echo "Заполненность раздела: $USAGE%"
echo "Установленный порог: $THRESHOLD%"

SERVICES=(
    "auth_service"
    "data_process_service"
    "system_event_handler_service"
)

if (( USAGE > THRESHOLD )); then
    echo "Порог превышен, проверяем папки"
    
    for service in "${SERVICES[@]}"; do 
        echo "Проверяем: $service"

        if ! DU_OUTPUT=$(du -s -B1 "$LOG_ROOT/$service"); then
            echo "Ошибка: не удалось определить размер папки $service"
            exit 1
        fi

        FOLDER_SIZE=$(printf '%s\n' "$DU_OUTPUT" | awk '{print $1}')

        if ((FOLDER_SIZE > MAX_FOLDER_SIZE)); then

            echo "Папка $service превысила квоту!"

            LOG_FILES=()

            while IFS= read -r FILE; do
                
                FILENAME="${FILE##*/}"
                NAME="${FILENAME%.log}"
                TIMESTAMP="${NAME##*_}"

                if ! [[ "$TIMESTAMP" =~ ^[0-9]+$ ]]; then

                    echo "Пропускаем файл с некорректным timestamp: $FILENAME"
                    continue
                
                fi

                echo "Файл: $FILENAME"
                echo "Timestamp: $TIMESTAMP"

                LOG_FILES+=("$TIMESTAMP:$FILE")

            done < <(find "$LOG_ROOT/$service" -maxdepth 1 -type f -name "*.log")
            
            if (( ${#LOG_FILES[@]} > 0 )); then
                mapfile -t LOG_FILES < <(printf '%s\n' "${LOG_FILES[@]}" | sort -n)
            fi

            COUNT=${#LOG_FILES[@]}
            TARGET_SIZE=$(( MAX_FOLDER_SIZE * THRESHOLD / 100) )
            BYTES_TO_FREE=$(( FOLDER_SIZE - TARGET_SIZE ))
            SELECTED_FILES=()

            for ((i = 0; i < COUNT - 1; i++)); do

                FILE="${LOG_FILES[i]#*:}"

                if ! DU_OUTPUT=$(du -B1 "$FILE"); then
                    echo "Ошибка: не удалось определить размер файла $FILE"
                    exit 1
                fi

                FILE_SIZE=$(printf '%s\n' "$DU_OUTPUT" | awk '{print $1}')

                SELECTED_FILES+=("$FILE")
                BYTES_TO_FREE=$(( BYTES_TO_FREE - FILE_SIZE ))

                if ((BYTES_TO_FREE <= 0)); then
                    break
                fi
            done

            if (( ${#SELECTED_FILES[@]} > 0)); then
                ARCHIVE_DIR="$ARCHIVE_ROOT/$service"
                mkdir -p "$ARCHIVE_DIR"

                ARCHIVE_NAME="archive_$(date +%s%N).tar.gz"
                ARCHIVE_PATH="$ARCHIVE_DIR/$ARCHIVE_NAME"

                while [[ -e "$ARCHIVE_PATH" ]]; do
                    ARCHIVE_NAME="archive_$(date +%s%N).tar.gz"
                    ARCHIVE_PATH="$ARCHIVE_DIR/$ARCHIVE_NAME"
                done

                if tar -czf "$ARCHIVE_PATH" -C "$LOG_ROOT/$service" "${SELECTED_FILES[@]##*/}"; then
                    
                    echo "Архив создан успешно"
                    
                    if tar -tzf "$ARCHIVE_PATH" > /dev/null; then
                        
                        echo "Архив читается успешно"
                        mapfile -t ARCHIVED_FILES < <(tar -tzf "$ARCHIVE_PATH")
                        ALL_FOUND=true
                        
                        for FILE in "${SELECTED_FILES[@]}"; do

                            FILENAME="${FILE##*/}"
                            FOUND=false
                            
                            for ARCHIVED in "${ARCHIVED_FILES[@]}"; do
                                
                                if [[ "$ARCHIVED" == "$FILENAME" ]]; then
                                    FOUND=true
                                    break
                                fi

                            done

                            if [[ "$FOUND" == false ]]; then
                                echo "Ошибка: $FILENAME остутсвует в архиве"
                                ALL_FOUND=false
                                break
                            fi

                        done

                        if [[ $ALL_FOUND == true ]]; then
                            
                            echo "Все выбранные файлы присутствуют в архиве"
                            rm -- "${SELECTED_FILES[@]}"
                            echo "Исходные логи удалены"
                        
                        else
                            echo "Архив неполный, удалять оригиналы нельзя"
                        fi
                    
                    else
                        echo "Ошибка: архив не прошёл проверку"
                    fi
                else
                    echo "Ошибка создания архива"
                    rm -f -- "$ARCHIVE_PATH"
                fi
            fi
            
        else
            echo "Папка $service в пределах квоты."
        fi

    done

else
    echo "Места достаточно, архивация не нужна" 
fi