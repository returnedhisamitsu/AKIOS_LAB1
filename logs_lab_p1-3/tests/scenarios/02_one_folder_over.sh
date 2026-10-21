#!/bin/bash

source "$(dirname "$0")/../lib.sh"
setup_env
export THRESHOLD=90

fill_folder auth_service 22 4
fill_folder data_process_service 3 3
fill_folder system_event_handler_service 3 3      

oldest=$(basename "$(oldest_log auth_service)")
newest=$(newest_log auth_service)
before_d=$(snapshot "$LOG_ROOT/data_process_service")
before_s=$(snapshot "$LOG_ROOT/system_event_handler_service")

usage_before=$(usage_pct)
run_cleaner

assert_rc 0
[ "$(usage_pct)" -lt "$usage_before" ] || _fail "заполненность не снизилась ($usage_before% -> $(usage_pct)%)"
assert_has_archive auth_service
assert_archived auth_service "$oldest"            
assert_exists "$newest"                           
assert_unchanged data_process_service "$before_d" 
assert_unchanged system_event_handler_service "$before_s"
finish
