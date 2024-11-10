#!/bin/sh
set -e -u
set -x

handle_sigterm() {
    # Caught SIGTERM. Terminating uvicorn app...
    kill -INT "$app_pid" 2>/dev/null
}
trap handle_sigterm TERM


this_script="$0"
services_dir=$(cd "$(dirname "$this_script")"; pwd)

export PYTHONPYCACHEPREFIX=/tmp/__crs_py_cache__
echo "service_dir=${services_dir}"

cd "${services_dir}" # run uvicorn inside services/ to add the folder to PYTHONPATH
# shellcheck disable=SC2068
uvicorn $@ &

app_pid=$!
echo "Waiting until $app_pid stopped"
wait "$app_pid"
