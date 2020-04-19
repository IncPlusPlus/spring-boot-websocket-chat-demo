#!/bin/bash

set -e

arch=$1
dir=$2
file_ready=false
ready_regex=".*(spring-boot-websocket-chat-demo-$arch\.tar).*"
wait_sleep_time_s=10
grep_cmd="ls $dir | grep -Ex \"$ready_regex\""
#Time in multiples of seconds to wait for the server to start up before quitting. This * $wait_sleep_time_s = num seconds
max_wait_time=6

#leave this variable at zero
time_waited=0

check_file_status() {
  echo Things look okay. ls output:
  ls
  exit 0
}

while [[ "$file_ready" == false ]]; do
  #  Check if the server is ready for us to hit it yet. Take a nap if it isn't.
  grep_status=$(
    eval "$grep_cmd" >/dev/null
    echo $?
  )
  case $grep_status in
  0)
    check_file_status
    ;;
  1)
    if [[ "$time_waited" -gt $((wait_sleep_time_s * max_wait_time)) ]]; then
      echo Timed out while waiting for tar file to appear.
      echo Content of "$dir"
      ls "$dir"
      exit 1
    else
      echo Tar file not found. Sleeping $wait_sleep_time_s seconds
      sleep $wait_sleep_time_s
      time_waited=$((time_waited + wait_sleep_time_s))
    fi
    ;;
  *)
    echo An error occurred while checking status. Grep returned status "$grep_status"
    echo Attempting grep again to print resulting error to console
    # shellcheck disable=SC2010
    # We don't care that we're doing $(ls | grep) because we are expecting very basic file names
    ls "$dir" | grep -Ex "$ready_regex"
    exit 1
    ;;
  esac
done
