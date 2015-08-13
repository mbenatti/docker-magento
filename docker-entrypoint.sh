#!/bin/bash

# fail on error
set -e

: ${PHP_MEMORY_LIMIT:=512M}
echo "memory_limit = 512M" >> /usr/local/etc/php/php.ini

db_host="$MYSQL_PORT_3306_TCP_ADDR"
db_port="$MYSQL_PORT_3306_TCP_PORT"

execute_mysql() {
	echo "Running 'mysql $@'"
	eval "mysql --host='$db_host' \
		--port='$db_port' \
		--user=root \
		--password='$MYSQL_ENV_MYSQL_ROOT_PASSWORD' \
		$@"
}

echo  "Waiting for mysql database on $db_host:$db_port..."

while ! mysqladmin ping --host="$db_host" --port="$db_port" --silent; do
	echo -n .
	sleep 1
done


# apply SQL patches
for sql_patch in $(ls /patches/*.sql); do
	echo "Applying SQL patch $sql_patch..."
	execute_mysql "$MYSQL_ENV_MYSQL_DATABASE < $sql_patch"
done



# Set host, username and password.
echo -n "Setting mysql login credentials in magento..."

cp /config/local.xml app/etc/

set_magento_config() {
	# escape /, \, & symbols
	value=$(echo $2 | sed -e 's/[/\&]/\\\&/g')
	sed -i "s/$1/$value/" "app/etc/local.xml"
}

set_magento_config DB_HOST "$db_host:$db_port"
set_magento_config DB_USER "$MYSQL_ENV_MYSQL_USER"
set_magento_config DB_PASSWORD "$MYSQL_ENV_MYSQL_PASSWORD"
set_magento_config DB_DATABASE "$MYSQL_ENV_MYSQL_DATABASE"
set_magento_config DB_PREFIX "$MAGENTO_DB_PREFIX"

echo " done."



echo "Applying magento settings..."

# set core config value with path $1 to value $2
set_db_config() {
	execute_mysql $MYSQL_ENV_MYSQL_DATABASE -e "\"update ${MAGENTO_DB_PREFIX}core_config_data set value = '$2' where path = '$1';\""
}

set_db_config "web/unsecure/base_url" "$MAGENTO_URL/"
set_db_config "web/secure/base_url" "$MAGENTO_URL/"
set_db_config "paypal/wpp/api_username" "$PAYPAL_USERNAME"
set_db_config "paypal/wpp/api_password" "$PAYPAL_PASSWORD"
set_db_config "paypal/wpp/api_signature" "$PAYPAL_SIGNATURE"
set_db_config "paypal/wpp/sandbox_flag" "$PAYPAL_SANDBOX_FLAG"


# hash a password the magento way:
# generate the md5 sum of <salt><password> and concatenate the salt.
hash_password() {
	# generate a random salt (length 32)
	salt=`LC_CTYPE=C tr -dc 'A-Za-z0-9' < /dev/urandom | fold -w 32 | head -n 1`
	md5hash=`echo -n "$salt${1}" | md5sum | awk '{ print $1 }'`
	echo -n "${md5hash}:$salt"
}

execute_mysql $MYSQL_ENV_MYSQL_DATABASE -e "\"update ${MAGENTO_DB_PREFIX}admin_user set password = '$(hash_password $MAGENTO_ADMIN_PASSWORD)' where username = 'admin';\""

echo " done."


exec "$@"
