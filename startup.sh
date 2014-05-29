#!/bin/bash

DB_USER="wordpress"
DB_PASS="$(pwgen -c -n -1 12)"
DB_HOST="localhost"
DB_NAME="wordpress"
DB_DEFAULTS="/root/.my.cnf"

# Check to see if WordPress is already installed
if [ ! -f "/var/www/html/wp-config.php" ] ; then
  # Start MySQL for database setup
  /usr/bin/mysqld_safe &
  sleep 5

  # Create the DB, then install WordPress
  mysql --defaults-extra-file=$DB_DEFAULTS -e "CREATE DATABASE $DB_NAME; GRANT ALL PRIVILEGES ON $DB_NAME.* TO \"$DB_USER\"@\"$DB_HOST\" IDENTIFIED BY \"$DB_PASS\"; DROP DATABASE test; FLUSH PRIVILEGES;"

  # Stop the rogue MySQL instance so we can run it with a supervisor
  /bin/kill -15 `cat /var/run/mysqld/mysqld.pid`
  sleep 10
fi

/bin/sed -e "s/database_name_here/$DB_NAME/
  s/username_here/$DB_USER/
  s/password_here/$DB_PASS/
  s/localhost/$DB_HOST/
  /'AUTH_KEY'/s/put your unique phrase here/$(pwgen -c -n -1 65)/
  /'SECURE_AUTH_KEY'/s/put your unique phrase here/$(pwgen -c -n -1 65)/
  /'LOGGED_IN_KEY'/s/put your unique phrase here/$(pwgen -c -n -1 65)/
  /'NONCE_KEY'/s/put your unique phrase here/$(pwgen -c -n -1 65)/
  /'AUTH_SALT'/s/put your unique phrase here/$(pwgen -c -n -1 65)/
  /'SECURE_AUTH_SALT'/s/put your unique phrase here/$(pwgen -c -n -1 65)/
  /'LOGGED_IN_SALT'/s/put your unique phrase here/$(pwgen -c -n -1 65)/
  /'NONCE_SALT'/s/put your unique phrase here/$(pwgen -c -n -1 65)/"

# Setting file permissions
/bin/chown -R apache /var/www/html/

##################
## BASE CONFIGS ##
##################

# Setup crond
/bin/bash -x /build/crond.sh

# Setup rsyslog
/bin/bash -x /build/rsyslog.sh

# Setup ssmtp
/bin/bash -x /build/ssmtp.sh

/bin/echo "Starting init system"
/sbin/runsvdir-start
