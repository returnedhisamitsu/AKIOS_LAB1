#!/bin/bash


DIR="$(cd "$(dirname "$0")" && pwd)"
CLEANER="${CLEANER:-$DIR/../scripts/log_cleanup.sh}"
export CLEANER

if [ ! -x "$CLEANER" ]; then
    echo "Не найден или не исполняемый: $CLEANER"
    echo "(chmod +x scripts/log_cleanup.sh или задайте CLEANER=...)"
    exit 2
fi

if [ "$EUID" -ne 0 ]; then
    echo "Тестам нужен root (они монтируют тестовый раздел): sudo tests/run_tests.sh"
    exit 2
fi

pass=0; fail=0
for sc in "$DIR"/scenarios/*.sh; do
    name="$(basename "$sc" .sh)"
    if bash "$sc"; then
        echo "PASS  $name"; pass=$((pass + 1))
    else
        echo "FAIL  $name"; fail=$((fail + 1))
    fi
done

echo "-----"
echo "Итого: $pass прошло, $fail упало"
[ "$fail" -eq 0 ]
