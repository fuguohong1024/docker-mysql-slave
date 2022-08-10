#!/bin/bash
set -eo pipefail
shopt -s nullglob

SERVER_ID=$(echo $(hostname -i)|sed 's/\.//g')

cat > /etc/mysql/mysql.conf.d/base.cnf << EOF
[mysqld]
log-bin=mysql-bin
relay-log=mysql-relay
bind-address=0.0.0.0
skip-name-resolve
EOF

# If there is a linked master use linked container information
if [ -n "$MASTER_PORT_3306_TCP_ADDR" ]; then
  export MASTER_HOST=$MASTER_PORT_3306_TCP_ADDR
  export MASTER_PORT=$MASTER_PORT_3306_TCP_PORT
fi

# is master
if [ -z "$MASTER_HOST" ]; then
  cat >/docker-entrypoint-initdb.d/init-master.sh  <<'EOF'
#!/bin/bash

echo Creating replication user ...
mysql -u root -p $MYSQL_ROOT_PASSWORD -e "\
  GRANT \
    FILE, \
    SELECT, \
    SHOW VIEW, \
    LOCK TABLES, \
    RELOAD, \
    REPLICATION SLAVE, \
    REPLICATION CLIENT \
  ON *.* \
  TO '$REPLICATION_USER'@'%' \
  IDENTIFIED BY '$REPLICATION_PASSWORD'; \
  FLUSH PRIVILEGES; \
"
EOF
  cat > /etc/mysql/mysql.conf.d/db-ignore.cnf <<'EOF'
[mysqld]
binlog-ignore-db=information_schema
binlog-ignore-db=performance_schema
binlog-ignore-db=mysql
binlog-ignore-db=sys
EOF
# is slave
else
  cp -v /init-slave.sh /docker-entrypoint-initdb.d/
  cat > /etc/mysql/mysql.conf.d/slave.cnf << EOF
[mysqld]
log-slave-updates
master-info-repository=TABLE
relay-log-info-repository=TABLE
relay-log-recovery=1
EOF
  cat > /etc/mysql/mysql.conf.d/db-ignore.cnf <<'EOF'
[mysqld]
replicate_ignore_db=information_schema
replicate_ignore_db=performance_schema
replicate_ignore_db=mysql
replicate_ignore_db=sys
EOF
fi

cat > /etc/mysql/mysql.conf.d/server-id.cnf << EOF
[mysqld]
server-id=$SERVER_ID
EOF

exec docker-entrypoint.sh "$@"

