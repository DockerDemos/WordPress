#!/bin/bash

DB_USER="wordpress"
DB_PASS="$(pwgen -c -n -1 12)"
DB_HOST="localhost"
DB_NAME="wordpress"
DB_DEFAULTS="/root/.my.cnf"

WORDPRESS='http://wordpress.org/latest.tar.gz'

SITENAME='Site_Install'
ADMINUSER='admin'
ADMINEMAIL='admin@example.org'
ADMINPASS="$(pwgen -c -n -1 12)"

f_killwait() {
  PIDFILE="$1"
  PID="$(cat $PIDFILE)"
  /bin/kill -15 $PID
  sleep 1
  while [[ ( -d /proc/$PID ) && ( -z `grep zombie /proc/$PID/status` ) ]]; do
    /bin/echo "Process $PID still hasn't exited"
    sleep 1
  done
}

# Check to see if WordPress is already installed
if [ ! -f "/var/www/html/wp-config.php" ] ; then
  # Start MySQL for database setup
  /usr/bin/mysqld_safe &
  sleep 5

  # Create the DB, then install WordPress
  mysql --defaults-extra-file=$DB_DEFAULTS -e "CREATE DATABASE $DB_NAME; GRANT ALL PRIVILEGES ON $DB_NAME.* TO \"$DB_USER\"@\"$DB_HOST\" IDENTIFIED BY \"$DB_PASS\"; DROP DATABASE test; FLUSH PRIVILEGES;"

  /bin/echo "Starting WordPress install"

  /usr/bin/wget -nv -O - $WORDPRESS | tar xz -C /var/www/html --strip-components=1
  
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
    /'NONCE_SALT'/s/put your unique phrase here/$(pwgen -c -n -1 65)/" \
  /var/www/html/wp-config-sample.php > /var/www/html/wp-config.php
  
  # Setting file permissions
  /bin/chown -R apache /var/www/html/

  #########################################################################
  ## IT WOULD BE LOVELY IF THIS SITE FINALIZATION WORKED, BUT IT DOESN'T ##
  #########################################################################

  # WordPress is just as uptight about the port it's setup with initially as
  # with the initial hostname.  UGH!

#  # Start Apache for final site install
#  /usr/sbin/httpd &
#  sleep 5
#  
#  # Finalize WP setup
#  /bin/echo '"Finalizing WordPress Setup'
#  
#  /usr/bin/wget -O /dev/null --post-data "weblog_title=$SITENAME&user_name=$ADMINUSER&admin_password=$ADMINPASS&admin_password2=$ADMINPASS&admin_email=$ADMINEMAIL&blog_public=1" http://localhost/wp-admin/install.php?step=2
#  
#  # Stop the rogue HTTPD and MySQL instances so we can run them with a supervisor
#  /bin/echo "Shutting down HTTPD"
#  f_killwait /var/run/httpd/httpd.pid
#
  /bin/echo "Shutting down MySQL"
  f_killwait /var/run/mysqld/mysqld.pid

  ##################
  ## BASE CONFIGS ##
  ##################
  
  # Setup crond
  /bin/bash -x /build/crond.sh
  
  # Setup rsyslog
  /bin/bash -x /build/rsyslog.sh
  
  # Setup ssmtp
  /bin/bash -x /build/ssmtp.sh


  /bin/echo "Setup complete"
  /bin/echo ""
  /bin/echo "##########################"
  /bin/echo "Admin user:     $ADMINUSER"
  /bin/echo "Admin password: $ADMINPASS"
  /bin/echo "##########################"

fi

/bin/echo "Starting init system"
/sbin/runsvdir-start
