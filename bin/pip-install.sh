#!/bin/bash

cat <<EOF

#
# `whoami`@`hostname`:$PWD$ pip-install.sh $@
#
# Install Python packages, if 'requiements*.txt' or 'setup.py' have changed.
# Make 'pip install --user' the default. Chainable.
#

EOF

set -e

pip() {
	if [[ "$1" = 'install' ]]; then
		shift
		set -- install --user "$@"
	fi
	command pip "$@"
}
export -f pip

if [[ ! -f venv.md5 ]]; then
	touch venv.md5
fi

export PATH="$PWD/venv/bin:$PATH"
export PIP_SRC="$PWD/venv/src"
export PYTHONUSERBASE="$PWD/venv"
if [[ ! -d venv ]] || ! md5sum -c --status venv.md5; then
	echo '# Python packages are out of date. Install.'

	# For some reason pip allows us to install sdist packages, but not editable
	# packages, when this directory doesn't exist. So make sure it does exist.
	mkdir -p "$PYTHONUSERBASE/lib/python2.7/site-packages"

	pip-accel install -r requirements.txt
	pip install -e .
	if [[ -f requirements-local.txt ]]; then
		pip install -r requirements-local.txt
	fi
	md5sum requirements*.txt setup.py > venv.md5
else
	echo '# Python packages are already up to date. Skip.'
fi

exec "$@"
