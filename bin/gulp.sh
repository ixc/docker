#!/bin/bash

# Install gulp and execute.

echo "# ${0}"

set -e

if [[ ! -f node_modules/.bin/gulp ]]; then
    echo 'Gulp is missing. Install.'
    npm install gulp
fi

exec gulp "$@"
