#!/bin/bash

source "$(dirname "$0")/../lib.sh"
setup_env
export THRESHOLD=90

for s in "${SERVICES[@]}"; do
    for i in 1 2 3; do make_log "$s" "$i" 3200; done   
done

before_a=$(snapshot "$LOG_ROOT/auth_service")
before_d=$(snapshot "$LOG_ROOT/data_process_service")
before_s=$(snapshot "$LOG_ROOT/system_event_handler_service")

run_cleaner

assert_rc 0
assert_unchanged auth_service "$before_a"
assert_unchanged data_process_service "$before_d"
assert_unchanged system_event_handler_service "$before_s"
finish
