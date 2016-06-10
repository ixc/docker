#!/bin/bash

cat <<EOF

#
# `whoami`@`hostname`:$PWD$ supervisor.sh $@
#
# Execute the 'supervisor' management command with the given arguments.
#

EOF

set -e

cd "$PROJECT_DIR"

exec python manage.py supervisor "$@"
