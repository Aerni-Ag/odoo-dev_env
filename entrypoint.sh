#!/bin/bash

set -e

# set the postgres database host, port, user and password according to the environment
# and pass them as arguments to the odoo process if not present in the config file
: ${HOST:=${DB_PORT_5432_TCP_ADDR:='db'}}
: ${PORT:=${DB_PORT_5432_TCP_PORT:=5432}}
: ${USER:=${DB_ENV_POSTGRES_USER:=${POSTGRES_USER:='odoo'}}}
: ${PASSWORD:=${DB_ENV_POSTGRES_PASSWORD:=${POSTGRES_PASSWORD:='odoo17@2023'}}}

# install python packages
pip3 install pip --upgrade
pip3 install -r /etc/odoo/requirements.txt

# sed -i 's|raise werkzeug.exceptions.BadRequest(msg)|self.jsonrequest = {}|g' /usr/lib/python3/dist-packages/odoo/http.py

# Installiere/Update Pakete - Stelle sicher, dass gosu installiert ist!
echo "INFO: Aktualisiere apt und installiere logrotate und gosu..."
apt-get update
# --no-install-recommends hält das Image kleiner; --fix-missing kann bei Problemen helfen
apt-get install -y logrotate --no-install-recommends --fix-missing
# Räume den apt-Cache auf
apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy logrotate config
cp /etc/odoo/logrotate /etc/logrotate.d/odoo

# Start cron daemon (required for logrotate)
cron

# Set ownership for Odoo user
echo "INFO: Changing ownership for Odoo data and addons directories..."
chown -R odoo:odoo /var/lib/odoo
chown -R odoo:odoo /mnt/extra-addons
if [ -f /etc/odoo/odoo.conf ]; then
    echo "INFO: Chowning /etc/odoo/odoo.conf..."
    chown odoo:odoo /etc/odoo/odoo.conf
fi
echo "INFO: Ownership changes complete."


DB_ARGS=()
function check_config() {
    param="$1"
    value="$2"
    if grep -q -E "^\s*\b${param}\b\s*=" "$ODOO_RC" ; then
        value=$(grep -E "^\s*\b${param}\b\s*=" "$ODOO_RC" |cut -d " " -f3|sed 's/["\n\r]//g')
    fi;
    DB_ARGS+=("--${param}")
    DB_ARGS+=("${value}")
}
check_config "db_host" "$HOST"
check_config "db_port" "$PORT"
check_config "db_user" "$USER"
check_config "db_password" "$PASSWORD"

case "$1" in
    -- | odoo)
        shift
        if [[ "$1" == "scaffold" ]] ; then
            exec odoo "$@"
        else
            wait-for-psql.py ${DB_ARGS[@]} --timeout=30
            exec odoo "$@" "${DB_ARGS[@]}"
        fi
        ;;
    -*)
        wait-for-psql.py ${DB_ARGS[@]} --timeout=30
        exec odoo "$@" "${DB_ARGS[@]}"
        ;;
    *)
        exec "$@"
esac

exit 1