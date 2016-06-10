#!/bin/bash

cat <<EOF

#
# `whoami`@`hostname`:$PWD$ setup-django-env.sh $@
#
# Setup environment for Django. Chainable.
#
# Set default 'PG*' variables, use a random Python hash seed, and wait for
# PostgreSQL to become available.
#

EOF

set -e

# Derive 'PGDATABASE' from 'PROJECT_NAME' and git branch or
# 'BASE_SETTINGS_MODULE', if not already defined.
if [[ -z "$PGDATABASE" ]]; then
	if [[ -d .git ]]; then
		export PGDATABASE="${PROJECT_NAME}_$(git rev-parse --abbrev-ref HEAD | sed 's/[^0-9A-Za-z]/_/g')"
		echo "# Derived database name '$PGDATABASE' from 'PROJECT_NAME' environment variable and git branch."
	elif [[ -n "$BASE_SETTINGS_MODULE" ]]; then
		export PGDATABASE="${PROJECT_NAME}_$BASE_SETTINGS_MODULE"
		echo "# Derived database name '$PGDATABASE' from 'PROJECT_NAME' and 'BASE_SETTINGS_MODULE' environment variables."
	else
		export PGDATABASE="$PROJECT_NAME"
		echo "# Derive database name '$PGDATABASE' from 'PROJECT_NAME' environment variable."
	fi
fi

# PostgreSQL.
export PGHOST="${PGHOST:-postgres}"
export PGPORT="${PGPORT:-5432}"
export PGUSER="${PGUSER:-postgres}"

# Python.
export PYTHONHASHSEED=random

# Wait for PostgreSQL to become available.
while ! psql -l > /dev/null 2>&1; do
	if [[ $((${COUNT:-0}+1)) -gt 10 ]]; then
		echo '# PostgreSQL still not available. Giving up.'
		exit 1
	fi
	echo '# Waiting for PostgreSQL...'
	sleep 1
done

exec "$@"
