#!/bin/bash

declare -x PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin

MYSQL_USER="__REPLACE__"
MYSQL_PASS="__REPLACE__"
FOLDER="__REPLACE__"

DAY=`/bin/date +'%a'`

echo "-- Removing node from pool --"
touch /tmp/clustercheck.disabled
sleep 60s
	
echo "-- Remove old backups --"
find $FOLDER -type f -ctime +6 -delete

echo "-- START new backups --"

echo "SET autocommit=0;SET unique_checks=0;SET foreign_key_checks=0;" > tmp_sqlhead.sql
echo "SET autocommit=1;SET unique_checks=1;SET foreign_key_checks=1;" > tmp_sqlend.sql

if [ -z "$1" ]
  then
    echo "-- Dumping all DB ..."
    for I in $(mysql -u $MYSQL_USER --password=$MYSQL_PASS -e 'show databases' -s --skip-column-names);
    do
      if [ "$I" = information_schema ] || [ "$I" =  mysql ] || [ "$I" =  phpmyadmin ] || [ "$I" =  performance_schema ]  # exclude this DB
      then
         echo "-- Skip $I ..."
       continue
      fi
      echo "-- Dumping $I ..."
      # Pipe compress and concat the head/end with the stoutput of mysqlump ( '-' cat argument)
      mysqldump -u $MYSQL_USER --password=$MYSQL_PASS --single-transaction --quick $I | cat tmp_sqlhead.sql - tmp_sqlend.sql | gzip -fc > "$FOLDER/$DAY-$I.sql.gz"
    done

else
      I=$1;
      echo "-- Dumping $I ..."
      # Pipe compress and concat the head/end with the stoutput of mysqlump ( '-' cat argument)
      mysqldump -u $MYSQL_USER --password=$MYSQL_PASS --single-transaction --quick $I | cat tmp_sqlhead.sql - tmp_sqlend.sql | gzip -fc > "$FOLDER/$DAY-$I.sql.gz"
fi

# remove tmp files
rm tmp_sqlhead.sql
rm tmp_sqlend.sql

echo "-- Adding node to pool again --"
rm /tmp/clustercheck.disabled

echo "-- FINISH —"
