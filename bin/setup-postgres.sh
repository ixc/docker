#!/bin/bash

cat <<EOF

#
# `whoami`@`hostname`:$PWD$ setup-postgres.sh $@
#
# Create database, 'PGDATABASE'. If 'SETUP_POSTGRES_FORCE' is set, drop and
# recreate it. Chainable.
#
# If 'SRC_PGDATABASE' is a file, execute it on 'PGDATABASE'. Otherwise, it is
# assumed to be the name of a database to dump and restore.
#
# If the source database is on a different host, 'SRC_PGHOST', 'SRC_PGPORT',
# 'SRC_PGUSER', and 'SRC_PGPASSWORD' can also be specified.
#

EOF

set -e

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
