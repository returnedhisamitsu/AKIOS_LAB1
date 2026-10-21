#!/bin/bash

source "$(dirname "$0")/../lib.sh"
setup_env
export THRESHOLD=90

run_cleaner

assert_rc 0
for s in "${SERVICES[@]}"; do
    [ -z "$(ls -A "$LOG_ROOT/$s")" ] || _fail "$s должна остаться пустой"
done
finish
