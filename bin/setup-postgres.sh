#!/bin/bash

cat <<EOF

#
# `whoami`@`hostname`:$PWD$ setup-postgres.sh $@

# Setup PostgreSQL. Chainable.
#
# Set 'PG*' variables, wait for PostgreSQL to become available, and create
# database, 'PGDATABASE'.
#
# If 'SETUP_POSTGRES_FORCE' is set, drop and recreate the database.
#
# If 'SRC_PGDATABASE' is a file, execute it on 'PGDATABASE'. Otherwise, it is
# assumed to be the name of a database to dump and restore from 'SRC_PG*',
# which match 'PG*' by default.
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

export PGHOST="${PGHOST:-postgres}"
export PGPORT="${PGPORT:-5432}"
export PGUSER="${PGUSER:-postgres}"

# Wait for PostgreSQL to become available.
while ! psql -l > /dev/null 2>&1; do
	if [[ $((${COUNT:-0}+1)) -gt 10 ]]; then
		echo '# PostgreSQL still not available. Giving up.'
		exit 1
	fi
	echo '# Waiting for PostgreSQL...'
	sleep 1
done

# If 'PGDATABASE' already exists, drop (when 'SETUP_POSTGRES_FORCE' is set) or
# exit.
if psql -l | grep -q "\b$PGDATABASE\b"; then
	if [[ -n "$SETUP_POSTGRES_FORCE" ]]; then
		echo "# Database '$PGDATABASE' already exists, and 'SETUP_POSTGRES_FORCE' is set. Drop."
		dropdb "$PGDATABASE"
	else
		echo "# Database '$PGDATABASE' already exists, but 'SETUP_POSTGRES_FORCE' is not set. Ignore."
		exec "$@"
	fi
fi

# Create database.
echo "# Create database '$PGDATABASE'."
createdb "$PGDATABASE"

# Restore from file or source database.
INITIAL_DATA="${SRC_PGDATABASE:-$PROJECT_DIR/initial_data.sql}"
if [[ -f "$INITIAL_DATA" ]]; then
	echo "# Restore to database '$PGDATABASE' from file '$INITIAL_DATA'."
	pv "$INITIAL_DATA" | psql -d "$PGDATABASE" > /dev/null
elif [[ -n "$SRC_PGDATABASE" ]]; then
	# Get source database credentials.
	SRC_PGHOST="${SRC_PGHOST:-${PGHOST}}"
	SRC_PGPASSWORD="${SRC_PGPASSWORD:-${PGPASSWORD}}"
	SRC_PGPORT="${SRC_PGPORT:-${PGPORT}}"
	SRC_PGUSER="${SRC_PGUSER:-${PGUSER}}"
	# Wait for PostgreSQL to become available.
	while ! PGPASSWORD="$SRC_PGPASSWORD" psql -l -h "$SRC_PGHOST" -p "$SRC_PGPORT" -U "$SRC_PGUSER" > /dev/null 2>&1; do
		if [[ $((${COUNT:-0}+1)) -gt 10 ]]; then
			echo '# PostgreSQL still not available. Giving up.'
			exit 1
		fi
		echo '# Waiting for PostgreSQL...'
		sleep 1
	done
	echo "# Restore database '$PGDATABASE' from source database '$SRC_PGDATABASE' on tcp://$SRC_PGHOST:$SRC_PGPORT."
	PGPASSWORD="$SRC_PGPASSWORD" pg_dump -d "$SRC_PGDATABASE" -h "$SRC_PGHOST" -p "$SRC_PGPORT" -U "$SRC_PGUSER" -O -x | pv | psql -d "$PGDATABASE" > /dev/null
fi

exec "$@"
