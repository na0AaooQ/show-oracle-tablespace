#!/bin/sh

export NLS_DATE_FORMAT="YYYY/MM/DD HH24:MI:SS"

SQL_TEXT="/home/ec2-user/show-oracle-tablespace/show_oracle_tablespace.sql"

if [ -r "${SQL_TEXT}" ] && [ -f "sqlplus" ] ; then

    sqlplus / as sysdba @${SQL_TEXT}

fi
