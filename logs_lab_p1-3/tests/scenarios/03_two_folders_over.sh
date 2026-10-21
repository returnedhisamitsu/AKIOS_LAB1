#!/bin/bash

source "$(dirname "$0")/../lib.sh"
setup_env
export THRESHOLD=90

fill_folder auth_service 13 4
fill_folder data_process_service 12 4
fill_folder system_event_handler_service 3 3      

old_a=$(basename "$(oldest_log auth_service)");         new_a=$(newest_log auth_service)
old_d=$(basename "$(oldest_log data_process_service)"); new_d=$(newest_log data_process_service)
before_s=$(snapshot "$LOG_ROOT/system_event_handler_service")

run_cleaner

assert_rc 0
assert_has_archive auth_service
assert_has_archive data_process_service
assert_archived auth_service "$old_a"
assert_archived data_process_service "$old_d"
assert_exists "$new_a"
assert_exists "$new_d"
assert_unchanged system_event_handler_service "$before_s"
finish
