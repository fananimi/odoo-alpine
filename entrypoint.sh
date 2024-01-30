#!/bin/bash
echo Running Odoo...

# run script to set/create new odoo.conf
python /write_config.py

export args="$@"
if [ -z "$args" ]
then
    export args=--
fi

# Init system variable
SHORT=r:,w:,d:,
LONG=db_host:,db_port:,db_user:,db_password:,
OPTS=$(getopt -a --options $SHORT --longoptions $LONG "$@")

eval set -- "$OPTS"

while :
do
  case "$1" in
    --db_host )
      sed -i "s/: \${DB_HOST:='localhost'}/: \${DB_HOST:='$2'}/g" /etc/profile.d/odoo.sh
      shift 2
      ;;
    --db_port )
      sed -i "s/: \${DB_PORT:=5432}/: \${DB_PORT:=$2}/g" /etc/profile.d/odoo.sh
      shift 2
      ;;
    -r | --db_user )
      sed -i "s/: \${DB_USER:='odoo'}/: \${DB_USER:='$2'}/g" /etc/profile.d/odoo.sh
      shift 2
      ;;
    -w | --db_password )
      sed -i "s/: \${DB_PASSWORD:='odoo'}/: \${DB_PASSWORD:='$2'}/g" /etc/profile.d/odoo.sh
      shift 2
      ;;
    - | -- )
      shift;
      break
      ;;
    *)
      echo "Unexpected option: $1"
      break
      ;;
  esac
done

source /etc/profile

# setup supervisord
sed -i "s#command = odoo.sh.*#command = odoo.sh $args#g" /etc/supervisor/conf.d/odoo.conf
supervisord --nodaemon --configuration /etc/supervisord.conf