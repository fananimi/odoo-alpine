# set the postgres database host, port, user and password according to the environment
# and pass them as arguments to the odoo process if not present in the config file
: ${DB_HOST:='localhost'}
: ${DB_PORT:=5432}
: ${DB_USER:='odoo'}
: ${DB_PASSWORD:='odoo'}

function set_var() {
    param="$1"
    value="$2"
    if grep -q -E "^\s*\b${param}\b\s*=" "$ODOO_RC" ; then
        value=$(grep -E "^\s*\b${param}\b\s*=" "$ODOO_RC" |cut -d " " -f3|sed 's/["\n\r]//g')
    fi;
    echo $value
}

export HOST="$(set_var db_host $DB_HOST)"
export PORT="$(set_var db_port $DB_PORT)"
export USER="$(set_var db_user $DB_USER)"
export PASSWORD="$(set_var db_password $DB_PASSWORD)"
