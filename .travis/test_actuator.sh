#!/bin/bash

set -e

container_id=$1
host=$2
port=$3
url=$4
endpoint_up=false
ready_regex=".*\w+ started on port\(s\):.*with context path.*"
server_wait_sleep_time_s=10
grep_cmd="docker logs $container_id | grep -Ex \"$ready_regex\""
desired_actuator_status="{\"status\":\"UP\"}"
#Time in multiples of seconds to wait for the server to start up before quitting. This * $server_wait_sleep_time_s = num seconds
max_wait_time=6

#leave this variable at zero
time_waited=0

check_actuator_status() {
  curl_result=$(curl -s "$host":"$port""$url")
  if [[ "$desired_actuator_status" == "$curl_result" ]]; then
    echo All good! Actuator status is as-expected.
    exit 0
  else
    echo ERROR! Expecting "$desired_actuator_status" but got "$curl_result"
    exit 1
  fi
}

while [[ "$endpoint_up" == false ]]; do
  #  Check if the server is ready for us to hit it yet. Take a nap if it isn't.
  grep_status=$(
    eval "$grep_cmd" >/dev/null
    echo $?
  )
  case $grep_status in
  0)
    check_actuator_status
    ;;
  1)
    if [[ "$time_waited" -gt $((server_wait_sleep_time_s * max_wait_time)) ]]; then
      echo Timed out while waiting for server to start.
      echo Docker containers:
      docker ps
      echo Printing log from server "("container id "$container_id"")"
      docker logs "$container_id"
      exit 1
    else
      echo Server not ready. Sleeping $server_wait_sleep_time_s seconds
      sleep $server_wait_sleep_time_s
      time_waited=$((time_waited + server_wait_sleep_time_s))
    fi
    ;;
  *)
    echo An error occurred while checking server status. Grep returned status "$grep_status"
    echo Printing latest log from server
    docker logs "$container_id"
    echo Attempting grep again to print resulting error to console
    docker logs "$container_id" | grep -Ex "$ready_regex"
    exit 1
    ;;
  esac
done
