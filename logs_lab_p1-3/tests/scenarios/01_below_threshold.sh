#!/bin/bash

source "$(dirname "$0")/../lib.sh"
setup_env
export THRESHOLD=90

fill_folder auth_service 12 4
fill_folder data_process_service 3 3
fill_folder system_event_handler_service 2 2      

before_a=$(snapshot "$LOG_ROOT/auth_service")
before_d=$(snapshot "$LOG_ROOT/data_process_service")
before_s=$(snapshot "$LOG_ROOT/system_event_handler_service")

run_cleaner

assert_rc 0
assert_unchanged auth_service "$before_a"
assert_unchanged data_process_service "$before_d"
assert_unchanged system_event_handler_service "$before_s"
finish
