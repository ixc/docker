#!/bin/bash

# Create database, `PGDATABASE`. If `SETUP_POSTGRES_FORCE` is set, drop and
# recreate it.
#
# If `SRC_PGDATABASE` is a file, execute it on `PGDATABASE`. Otherwise, it is
# assumed to be the name of a database to dump and restore.
#
# If the source database is on a different host, `SRC_PGHOST`, `SRC_PGPORT`,
# `SRC_PGUSER`, and `SRC_PGPASSWORD` can also be specified.

echo "# ${0}"

set -e

# If `PGDATABASE` already exists, drop (when `SETUP_POSTGRES_FORCE` is set) or exit.
if psql -l | grep -q "\b${PGDATABASE}\b"; then
    if [[ -n "${SETUP_POSTGRES_FORCE}" ]]; then
        echo "Database '${PGDATABASE}' already exists, and SETUP_POSTGRES_FORCE set. Drop."
        dropdb "${PGDATABASE}"
    else
        echo "Database '${PGDATABASE}' already exists, but SETUP_POSTGRES_FORCE not set. Ignore."
        exec "$@"
    fi
fi

# Create database.
echo "Create database '${PGDATABASE}'."
createdb "${PGDATABASE}"

# Restore from file or source database.
INITIAL_DATA="${SRC_PGDATABASE:-${PROJECT_DIR}/initial_data.sql}"
if [[ -f "${INITIAL_DATA}" ]]; then
    echo "Restore to database '${PGDATABASE}' from file '${INITIAL_DATA}'."
    psql -d "${PGDATABASE}" -f "${INITIAL_DATA}" -q
elif [[ -n "${SRC_PGDATABASE}" ]]; then
    # Get source database credentials.
    SRC_PGHOST="${SRC_PGHOST:-${PGHOST}}"
    SRC_PGPASSWORD="${SRC_PGPASSWORD:-${PGPASSWORD}}"
    SRC_PGPORT="${SRC_PGPORT:-${PGPORT}}"
    SRC_PGUSER="${SRC_PGUSER:-${PGUSER}}"
    # Wait for source database server to become available.
    # dockerize -wait "tcp://${SRC_PGHOST}:${SRC_PGPORT}"
    echo "Restore database '${PGDATABASE}' from source database '${SRC_PGDATABASE}' on tcp://${SRC_PGHOST}:${SRC_PGPORT}."
    PGPASSWORD="${SRC_PGPASSWORD}" pg_dump -d "${SRC_PGDATABASE}" -h "${SRC_PGHOST}" -p "${SRC_PGPORT}" -U "${SRC_PGUSER}" -O -x | psql -d "${PGDATABASE}" -q
fi

exec "$@"
