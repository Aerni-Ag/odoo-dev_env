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
echo "INFO: Aktualisiere apt und installiere logrotate..."
apt-get update
# --no-install-recommends hält das Image kleiner; --fix-missing kann bei Problemen helfen
# gosu ist nicht explizit in diesem Skript verwendet, aber oft in Odoo Entrypoints. Wenn es nicht benötigt wird, kann es entfernt werden.
apt-get install -y logrotate --no-install-recommends --fix-missing
# Räume den apt-Cache auf
apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy logrotate config
cp /etc/odoo/logrotate /etc/logrotate.d/odoo

# Start cron daemon (required for logrotate)
cron

# Set ownership for Odoo user
echo "INFO: Changing ownership for Odoo data directory..."
chown -R odoo:odoo /var/lib/odoo

echo "INFO: Changing ownership for extra-addons directory (skipping .git folders)..."
# Zuerst das Hauptverzeichnis /mnt/extra-addons selbst bearbeiten
chown odoo:odoo /mnt/extra-addons
# Dann alle Inhalte, außer .git Verzeichnisse und deren Inhalte
# -mindepth 1, damit /mnt/extra-addons nicht erneut von find verarbeitet wird
# Wir suchen nach Verzeichnissen (-type d) mit dem Namen ".git" und -prune sie (nicht weiterverfolgen)
# Für alles andere (-o), wird chown ausgeführt.
find /mnt/extra-addons -mindepth 1 \( -type d -name ".git" -prune \) -o -exec chown odoo:odoo {} +

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
            # Es wird oft `gosu odoo` hier verwendet, um den Odoo Prozess als odoo Benutzer zu starten.
            # Wenn das so sein soll, muss gosu installiert sein und der Aufruf angepasst werden.
            # Z.B.: exec gosu odoo wait-for-psql.py ...
            # Und: exec gosu odoo odoo "$@" "${DB_ARGS[@]}"
            wait-for-psql.py ${DB_ARGS[@]} --timeout=30
            exec odoo "$@" "${DB_ARGS[@]}"
        fi
        ;;
    -*)
        # Hier ebenfalls ggf. gosu odoo verwenden
        wait-for-psql.py ${DB_ARGS[@]} --timeout=30
        exec odoo "$@" "${DB_ARGS[@]}"
        ;;
    *)
        exec "$@"
esac

exit 1