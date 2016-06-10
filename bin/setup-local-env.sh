#!/bin/bash

cat <<EOF

#
# `whoami`@`hostname`:$PWD$ setup-local-env.sh $@
#
# Setup environment for local development. Chainable.
#
# Disable SSH strict host checking and conditionally install Node.js packages,
# Bower components, and Python packages, when 'package.json', 'bower.json',
# 'requirements*.txt', or 'setup.py' have changed.
#

EOF

set -e

# There is no need to setup the local env when the project directory owned by
# 'root', which means it is not bind mounted from the host.
if [[ $(stat -c '%U' "$PROJECT_DIR") = 'root' ]]; then
	echo "# Directory '$PROJECT_DIR' is not bind mounted from the host. Skip."
	exec "$@"
fi

cd "$PROJECT_DIR/var"

# Disable SSH strict host checking.
if [[ -f .ssh/id_dsa ]]; then
	cat <<-EOF > "$HOME/.ssh/config"
	Host *
		IdentityFile /etc/ssh/id_dsa
		StrictHostKeyChecking no
	EOF
fi

# Create empty initial MD5 signatures.
for FILE in bower.json package.json venv
do
	if [[ ! -f "$FILE.md5" ]]; then
		touch "$FILE.md5"
	fi
done

# Node.js packages.
export NODE_MODULES_BIN="$PWD/node_modules/.bin"
export PATH="$NODE_MODULES_BIN:$PATH"
if [[ ! -f node_modules/setup.txt ]] || ! md5sum -c --status package.json.md5; then
	echo '# Node modules are out of date. Install.'
	cp -f ../package.json .
	npm install
	echo '# This file indicates that setup-local-env.sh has installed node modules.' > node_modules/setup.txt
	md5sum ../package.json > package.json.md5
else
	echo '# Node modules are already up to date. Skip.'
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
if [[ ! -d "$BOWER_DIR" ]] || ! md5sum -c --status bower.json.md5; then
	echo '# Bower components are out of date. Install.'
	cp -f ../bower.json .
	bower install --allow-root
	md5sum ../bower.json > bower.json.md5
else
	echo '# Bower components are already up to date. Skip.'
fi

# Python packages.
export PATH="$PWD/venv/bin:$PATH"
export PIP_SRC="$PWD/venv/src"
export PYTHONUSERBASE="$PWD/venv"
if [[ ! -d venv ]] || [[ $(md5sum ../requirements*.txt ../setup.py) != $(cat venv.md5) ]]; then
	echo '# Python packages are out of date. Install.'
	cd ..  # Change directory because requirements.txt might have relative paths

	# For some reason pip allows us to install sdist packages, but not editable
	# packages, when this directory doesn't exist. So make sure it does exist.
	mkdir -p "$PYTHONUSERBASE/lib/python2.7/site-packages"

    # Use pip, because pip-accel wants to build an sdist package to cache.
	pip install -r requirements.txt -e . --user
	if [[ -f requirements-local.txt ]]; then
		pip install -r requirements-local.txt --user
	fi

	cd -  # Change back to var directory
	md5sum ../requirements*.txt ../setup.py > venv.md5
else
	echo '# Python packages are already up to date. Skip.'
fi

cd "$PROJECT_DIR"

exec "$@"
