#!/bin/bash

cat <<EOF

#
# `whoami`@`hostname`:$PWD$ migrate.sh $@
#
# Apply Django migrations, if they are out of date. Chainable.
#

EOF

set -e

cd "$PROJECT_DIR"

# For Django 1.6 and below, we can't tell if apps without migrations need to be
# synced, so we always run the 'syncdb' management command.
if [[ "$(django-admin.py --version)" < 1.7 ]]; then
	python manage.py syncdb
fi

touch var/migrate.md5
python manage.py migrate --list > var/migrate.txt

if md5sum -c --status var/migrate.md5; then
	echo '# Migrations are already up to date. Skip.'
else
	echo '# Migrations are out of date. Apply.'
	python manage.py migrate --noinput
	python manage.py migrate --list > var/migrate.txt
	md5sum var/migrate.txt > var/migrate.md5
fi

exec "$@"
