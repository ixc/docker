#!/bin/bash

# Setup local development environment and execute command.
#
# Create a virtualenv and conditionally install Node.js packages, Bower
# components, and Python packages, when `package.json`, `bower.json`,
# `requirements*.txt`, or `setup.py` have changed.

echo "# ${0}"

set -e

# Skip when explicitly requested.
if [[ -n "${SETUP_LOCAL_ENV_SKIP}" ]]; then
    echo "SETUP_LOCAL_ENV_SKIP environment variable is set. Skip."
    exec "$@"
fi

# There is no need to setup the local env when the source directory is not
# owned by the current user, which means it is not bind mounted from the host.
if [[ $(stat -c '%u' "${PROJECT_DIR}") != $(id -u) ]]; then
    echo "Directory '${PROJECT_DIR}' is not bind mounted from the host. Skip."
    exec "$@"
fi

cd "${PROJECT_DIR}/var"

export NODE_MODULES_BIN=${PROJECT_DIR}/var/node_modules/.bin
export PATH="${NODE_MODULES_BIN}:${PROJECT_DIR}/var/venv/bin:$PATH"

# Create empty initial MD5 signatures.
for FILE in bower.json package.json venv
do
    if [[ ! -f "$FILE.md5" ]]; then
        touch "$FILE.md5"
    fi
done

# Node.js packages.
if [[ ! -f node_modules/setup.txt ]] || ! md5sum -c --status package.json.md5; then
    echo 'Node modules are out of date. Install.'
    cp -f ../package.json .
    npm install
    echo 'This file indicates that setup.sh has installed node modules.' > node_modules/setup.txt
    md5sum ../package.json > package.json.md5
else
    echo 'Node modules are already up to date. Skip.'
fi

# Bower components.
if [[ -f ../.bowerrc ]]; then
    BOWER_DIR=$(jq -r '.directory' ../.bowerrc)
    cp -f ../.bowerrc .
else
    BOWER_DIR="bower_components"
    if [[ -f .bowerrc ]]; then
        rm .bowerrc
    fi
fi
if [[ ! -d ${BOWER_DIR} ]] || ! md5sum -c --status bower.json.md5; then
    echo 'Bower components are out of date. Install.'
    cp -f ../bower.json .
    bower install --allow-root
    md5sum ../bower.json > bower.json.md5
else
    echo 'Bower components are already up to date. Skip.'
fi

# Python virtualenv.
if [[ ! -d venv ]]; then
    echo 'Python virtualenv does not exist. Create.'
    virtualenv venv
    # Because `pip-accel` wraps pip, we need to reinstall it into the venv to
    # ensure packages installed via `pip-accel` get installed into the venv.
    pip install --no-cache-dir pip-accel
    truncate -s 0 venv.md5
else
    echo 'Python virtualenv already exists. Skip.'
fi

# Python packages.
if [[ $(md5sum ../requirements*.txt ../setup.py) != $(cat venv.md5) ]]; then
    echo 'Python packages are out of date. Install.'
    cd ..  # Change directory because requirements.txt might have relative paths
    pip-accel install -r requirements.txt
    if [[ -f requirements-local.txt ]]; then
        pip-accel install -r requirements-local.txt
    fi
    pip install --no-cache-dir -e .
    cd -  # Change back to var directory
    md5sum ../requirements*.txt ../setup.py > venv.md5
else
    echo 'Python packages are already up to date. Skip.'
fi

cd "${PROJECT_DIR}"

exec "$@"
