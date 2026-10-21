#!/bin/bash

source "$(dirname "$0")/../lib.sh"
setup_env
export THRESHOLD=50

make_log auth_service 1 12288                     
fill_folder data_process_service 2 2
fill_folder system_event_handler_service 2 2      

only=$(newest_log auth_service)
before_a=$(snapshot "$LOG_ROOT/auth_service")

run_cleaner

assert_rc 0
assert_exists "$only"
assert_no_archive auth_service
assert_unchanged auth_service "$before_a"
finish
