#!/bin/bash

cat <<EOF

# setup-user.sh
#
# Create an unprivileged user with the given username and home directory. If
# the user already exists, change its UID and GID to match the directory. If
# the directory already exists and is owned by root, change its UID and GID to
# match the user.

EOF

set -e

USERNAME="$1"
DIR="$2"

if [[ -z "${USERNAME}" ]] || [[ -z "${DIR}" ]]; then
    echo '# Missing required `USERNAME` or `DIR` positional arguments. Abort.'
    exit 1
fi

# Create user and directory.
if ! id "${USERNAME}" 2> /dev/null; then
    echo "# User '${USERNAME}' does not exist. Create."
    if [[ -d "${DIR}" ]]; then
        echo "# Home directory '${DIR}' already exists."
        adduser --system --home "${DIR}" --no-create-home "${USERNAME}"
    else
        echo "# Home directory '${DIR}' does not exist. Create."
        adduser --system --home "${DIR}" "${USERNAME}"
    fi
fi

# Get UID and GID for user and home directory.
DIR_GID=$(stat -c '%g' "${DIR}")
DIR_UID=$(stat -c '%u' "${DIR}")
USER_GID=$(id -g "${USERNAME}")
USER_UID=$(id -u "${USERNAME}")

# Change user or directory UID and GID to match.
if [[ "${USER_UID}" != "${DIR_UID}" ]] || [[ "${USER_GID}" != "${DIR_GID}" ]]; then
    if [[ "${DIR_UID}" == 0 ]]; then
        echo "# Directory '${DIR}' is owned by root. Change owner."
        chown -R "${USER_UID}:${USER_GID}" "${DIR}" || true  # Allow non-zero exit code
    else
        echo "# UID and GID for user '${USERNAME}' (${USER_UID}:${USER_GID}) do not match directory '${DIR}' (${DIR_UID}:${DIR_GID}). Modify."
        usermod -u "${DIR_UID}" "${USERNAME}"
    fi
fi
