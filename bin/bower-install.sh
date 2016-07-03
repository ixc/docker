#!/bin/bash

cat <<EOF

#
# `whoami`@`hostname`:$PWD$ bower-install.sh $@
#
# Install Bower components, if 'bower.json' has changed. Chainable.
#

EOF

set -e

if [[ ! -f bower.json.md5 ]]; then
	touch bower.json.md5
fi

if [[ -f .bowerrc ]]; then
	BOWER_DIR=$(jq -r '.directory' .bowerrc)
else
	BOWER_DIR="bower_components"
fi

if [[ ! -d "$BOWER_DIR" ]] || ! md5sum -c --status bower.json.md5; then
	echo '# Bower components are out of date. Install.'
	bower install --allow-root
	md5sum bower.json > bower.json.md5
else
	echo '# Bower components are already up to date. Skip.'
fi

exec "$@"
