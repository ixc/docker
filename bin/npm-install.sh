#!/bin/bash

cat <<EOF

#
# `whoami`@`hostname`:$PWD$ npm-install.sh $@
#
# Install NPM packages, if 'package.json' has changed. Chainable.
#

EOF

set -e

if [[ ! -f package.json.md5 ]]; then
	touch package.json.md5
fi

if [[ ! -d node_modules ]] || ! md5sum -c --status package.json.md5; then
	echo '# Node modules are out of date. Install.'
	npm install
	md5sum package.json > package.json.md5
else
	echo '# Node modules are already up to date. Skip.'
fi

exec "$@"
