#!/usr/bin/env bash

set -xeuo pipefail

case "${1:-}" in
    "ranger-admin" ) ;;
    "ranger-usersync" ) ;;
    "ranger-tagsync" ) exec bash "${RANGER_BASE}"/start.sh ;;
    * ) echo "Unknown option provided: '${1:-}'"; exit 1; ;;
esac

# set default permissions so members of the group can write to files
umask 0002

if [ -v WAIT_FOR ]; then
  WAIT_TIMEOUT="${WAIT_TIMEOUT:-120}"
  wait-for-it "${WAIT_FOR}" -t "${WAIT_TIMEOUT}" -- echo "Waiting for $WAIT_FOR completed"
fi

"${RANGER_BASE}"/prop-updater.py  "${RANGER_BASE}"/install.properties "${RANGER_HOME}"/install.properties

cd "${RANGER_HOME}"
./setup.sh

ranger-admin start

wait-for-it "localhost:6080"

if [ -d "/scripts" ]
then
    for SCRIPT in /scripts/*.py ; do
        python3 "$SCRIPT" "$@"
    done
fi

LOGS_DIR="${RANGER_HOME}/ews/logs"
echo "ranger-admin started at $(date)" >> "${LOGS_DIR}"/start.sh.log
# Keep the container running
tail -f "${LOGS_DIR}"/*
