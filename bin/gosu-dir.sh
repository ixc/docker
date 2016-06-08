#!/bin/bash

# Execute a command with the same UID and GID as the given directory.

echo "# ${0}"

set -e

DIR="$1"

if [[ ! -d "${DIR}" ]]; then
    echo "Directory '${DIR}' does not exist. Abort."
    exit 1
fi

DIR_GID=$(stat -c '%g' "${DIR}")
DIR_UID=$(stat -c '%u' "${DIR}")

exec gosu "${DIR_UID}:${DIR_UID}" "${@:2}"
