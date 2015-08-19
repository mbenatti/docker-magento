#!/bin/sh

timestamp() {
	date +"%Y-%m-%d_%H-%M-%S"
}

if ! [ -e /backups ]; then
	echo "Target directory /backups does not exist. Maybe you forgot to specify a docker volume?"
	echo "Make sure to run this container with something like"
	echo "\n\t--volume \"\$(pwd)your-backups-directory:/backups\""
	exit 1
fi

mysqldump --host $MYSQL_PORT_3306_TCP_ADDR \
	--port $MYSQL_PORT_3306_TCP_PORT \
	--user root \
	--password=$MYSQL_ENV_MYSQL_ROOT_PASSWORD \
	--skip-comments \
	$MYSQL_ENV_MYSQL_DATABASE > "/backups/livedump-$(timestamp).sql"

