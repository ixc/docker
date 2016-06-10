#!/bin/bash

cat <<EOF

#
# `whoami`@`hostname`:$PWD$ gosu-dir.sh $@
#
# Execute a command as the owner of the given directory. If no user exists, one
# will be created with a random username.
#

EOF

set -e

GOSU_DIR="$1"
GOSU_USERNAME="gosu_$(cat /dev/urandom | tr -dc '0-9a-z' | fold -w 8 | head -n 1)"

if [[ ! -d "$GOSU_DIR" ]]; then
	echo "# Directory '$GOSU_DIR' does not exist. Create new user '$GOSU_USERNAME' and directory."
	adduser --system "$GOSU_USERNAME"
else
	GOSU_UID=$(stat -c '%u' "$GOSU_DIR")
	if ! id "$GOSU_UID" > /dev/null 2>&1; then
		echo "# Directory '$GOSU_DIR' already exists. Create new user '$GOSU_USERNAME'."
		adduser --system --uid "$GOSU_UID" "$GOSU_USERNAME"
	else
		GOSU_USERNAME=$(id -n -u "$GOSU_UID")
		echo "# User '$GOSU_USERNAME' and directory '$GOSU_DIR' already exists. Nothing to do."
	fi
fi

exec gosu $(stat -c '%u' "$GOSU_DIR"):$(stat -c '%g' "$GOSU_DIR") "${@:2}"
