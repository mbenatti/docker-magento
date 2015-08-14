#!/bin/sh

timestamp() {
	date +"%Y-%m-%d_%H-%M-%S"
}

mysqldump --host $MYSQL_PORT_3306_TCP_ADDR \
	--port $MYSQL_PORT_3306_TCP_PORT \
	--user root \
	--password=$MYSQL_ENV_MYSQL_ROOT_PASSWORD \
	--skip-comments \
	$MYSQL_ENV_MYSQL_DATABASE > "/backups/livedump-$(timestamp).sql"

