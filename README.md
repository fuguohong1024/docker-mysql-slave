```
NOTE: THIS PROJECT WAS DEVELOPED AS A RPOOF OF CONCEPT PROJECT THAT HAS NEVER BEEN USED

PLEASE CHECK THE CODE AND USE IT ON YOUR OWN RISK
```

Docker images to support implicit mysql replication support.

Features:
* based on official mysql images
* when you start the slave, it starts with replication started,
* no manual sync (mysqldump) is needed,
* slave fails to start if replication not healthy

Additional environment variables:
* REPLICATION_USER [default: replication]
* REPLICATION_PASSWORD [default: replication_pass]
* REPLICATION_HEALTH_GRACE_PERIOD [default: 3]
* REPLICATION_HEALTH_TIMEOUT [default: 10]
* MASTER_PORT [default: 3306]
* MASTER_HOST [default: master]
* MYSQLDUMP_PORT [default: $MASTER_PORT]
* MYSQLDUMP_HOST [default: $MASTER_HOST]

# Start master

```
docker run -d \
  --name mysql_master \
  -e MYSQL_ROOT_PASSWORD=root \
  bergerx/mysql-replication:5.7
```

# Start slave

```
docker run -d \
  --name mysql_slave \
  -e MYSQL_ROOT_PASSWORD=root \
  --link mysql_master:master \
  bergerx/mysql-replication:5.7
```