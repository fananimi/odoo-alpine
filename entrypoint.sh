#!/bin/bash
echo Running Odoo...

export args="$@"
if [ -z "$args" ]
then
    export args=--
fi

# Init system variable
SHORT=r:,w:,
LONG=db_host:,db_port:,db_user:,db_password:,
OPTS=$(getopt -a -n weather --options $SHORT --longoptions $LONG "$@")

eval set -- "$OPTS"

while :
do
  case "$1" in
    --db_host )
      db_host="$2"
      shift 2
      ;;
    --db_port )
      db_port="$2"
      shift 2
      ;;
    -r | --db_user )
      db_user="$2"
      shift 2
      ;;
    -w | --db_password )
      db_password="$2"
      shift 2
      ;;
    --)
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
sed -i '/command =/ s/= .*/= odoo.sh '"$args"'/g' /etc/supervisor/conf.d/odoo.conf
supervisord --nodaemon --configuration /etc/supervisord.conf
