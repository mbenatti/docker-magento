#!/bin/bash

set -e
set -o pipefail


database="$MYSQL_ENV_MYSQL_DATABASE"
password="$MYSQL_ENV_MYSQL_ROOT_PASSWORD"
host="$MYSQL_PORT_3306_TCP_ADDR"
port="$MYSQL_PORT_3306_TCP_PORT"


dumpTable() {
	outfile=$1
	table=$2

	echo "Saving table to $outfile"

	mysqldump --host="$host" \
		--port="$port" \
		--user="root" \
		--password="$password" \
		--skip-comments \
		$database \
		$table \
	> /patches/tempfile

	if [ -s /patches/tempfile ]; then
		mv /patches/tempfile $outfile
	else
		rm /patches/tempfile
	fi
}


rm -rf "/sql/patches/*"

tables_to_save=$(grep -Ev "^\s*(#|$)" /patches/sql_tables)

for table in $tables_to_save; do
	dumpTable "/sql/patches/${table}.sql" "${MAGENTO_DB_PREFIX}$table"
done
