#!/bin/bash


TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLEANER="${CLEANER:-$TESTS_DIR/../scripts/log_cleanup.sh}"
SERVICES=(auth_service data_process_service system_event_handler_service)
PART_SIZE_MB=30             
BASE_TS=1760000000          
FAILED=0
RC=0
OUT=""


_cleanup() {
    umount "$LOG_ROOT" 2>/dev/null
    rm -rf "$LOG_ROOT" "$ARCHIVE_ROOT"
}

setup_env() {
    if [ "$EUID" -ne 0 ]; then
        echo "    Нужен root (mount): запустите через sudo"; exit 2
    fi
    LOG_ROOT="$(mktemp -d /tmp/logguard_part.XXXXXX)"
    ARCHIVE_ROOT="$(mktemp -d /tmp/logguard_arch.XXXXXX)"
    export LOG_ROOT ARCHIVE_ROOT
    trap _cleanup EXIT
    mount -t tmpfs -o size="${PART_SIZE_MB}m" tmpfs "$LOG_ROOT"
    for s in "${SERVICES[@]}"; do mkdir -p "$LOG_ROOT/$s"; done
}

make_log() {
    local service="$1" idx="$2" size_kb="$3"
    local ts=$((BASE_TS + idx * 86400))
    local day
    day="$(date -u -d "@$ts" +%Y_%m_%d)"
    dd if=/dev/urandom of="$LOG_ROOT/$service/${service}_${day}_${ts}.log" \
       bs=1K count="$size_kb" status=none
}

fill_folder() {
    local service="$1" total_mb="$2" n="$3"
    local per_kb=$(( total_mb * 1024 / n )) i
    for ((i = 1; i <= n; i++)); do make_log "$service" "$i" "$per_kb"; done
}


run_cleaner() {
    OUT="$("$CLEANER" 2>&1)"
    RC=$?
}


oldest_log() { ls "$LOG_ROOT/$1"/*.log 2>/dev/null | sort | head -n1; }
newest_log() { ls "$LOG_ROOT/$1"/*.log 2>/dev/null | sort | tail -n1; }
count_logs() { ls "$LOG_ROOT/$1"/*.log 2>/dev/null | wc -l; }
count_archives() { ls "$ARCHIVE_ROOT/$1"/*.tar.gz 2>/dev/null | wc -l; }
usage_pct() { df -P "$LOG_ROOT" | awk 'NR==2 {gsub("%","",$5); print $5}'; }

snapshot() {
    ( cd "$1" 2>/dev/null && find . -type f -printf '%p %s\n' | sort \
        && find . -type f -exec md5sum {} + | sort ) | md5sum | cut -d' ' -f1
}


_fail() { echo "    FAIL: $*"; FAILED=1; }

assert_rc() {
    [ "$RC" -eq "$1" ] || _fail "код возврата $RC, ожидался $1. Вывод: $OUT"
}
assert_exists()     { [ -e "$1" ] || _fail "файл должен существовать: $1"; }
assert_not_exists() { [ ! -e "$1" ] || _fail "файл должен быть удалён: $1"; }

assert_has_archive() {
    [ "$(count_archives "$1")" -ge 1 ] || _fail "в $ARCHIVE_ROOT/$1 нет .tar.gz архива"
}
assert_no_archive() {
    [ "$(count_archives "$1")" -eq 0 ] || _fail "в $ARCHIVE_ROOT/$1 не должно быть архивов"
}

assert_archived() {
    local service="$1" file="$2" found=0 a
    [ ! -e "$LOG_ROOT/$service/$file" ] || _fail "$file не удалён из $service после архивации"
    for a in "$ARCHIVE_ROOT/$service"/*.tar.gz; do
        [ -e "$a" ] || continue
        tar -tzf "$a" 2>/dev/null | grep -qx "$file" && found=1
    done
    [ "$found" -eq 1 ] || _fail "$file не найден ни в одном архиве $service"
}

assert_unchanged() {
    [ "$(snapshot "$LOG_ROOT/$1")" = "$2" ] || _fail "папка логов $1 изменилась, а не должна была"
    assert_no_archive "$1"
}

finish() { [ "$FAILED" -eq 0 ]; exit $?; }
