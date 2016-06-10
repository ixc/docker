#!/bin/bash

cat <<EOF

#
# `whoami`@`hostname`:$PWD$ gulp.sh $@
#
# Install gulp locally, because it must be installed locally, and execute with
# the given arguments.
#

EOF

set -e

if [[ ! -f node_modules/.bin/gulp ]]; then
	echo '# Gulp is missing. Install.'
	npm install gulp
fi

exec gulp "$@"
