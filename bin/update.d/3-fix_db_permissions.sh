#! /bin/bash

#
# FIX DATABASE PERMISSIONS
# This script will fix various database permissions for the web_usr user
#

BB_HOME="$1"
SERVICE="$2"
BREEDBASE="$BB_HOME/bin/breedbase"
DOCKER_COMPOSE_FILE="$BB_HOME/docker-compose.yml"
BB_CONFIG_DIR="$BB_HOME/config/"

# SQL to fix Database Permissions
SQL_FILE="$BB_HOME/bin/update.d/3-web_usr_grants.sql"
SQL=$(cat "$SQL_FILE")

# Docker compose location
DOCKER_COMPOSE=$(which docker-compose)
DOCKER_DB_SERVICE="breedbase_db"


# Get the defined web services
if [ -z "$SERVICE" ]; then
    services=$("$DOCKER_COMPOSE" -f "$DOCKER_COMPOSE_FILE" config --services)
    IFS=$'\n' read -d '' -r -a services <<< "$services"
else
    services="$SERVICE"
fi


echo "==> Setting Database Permissions..."


# Process each web instance
for service in "${services[@]}"; do
   if [[ "$service" != "$DOCKER_DB_SERVICE" ]]; then
        echo "... fixing $service database"

        # Run web_usr_grants commands
        db=$(cat "$BB_CONFIG_DIR/$service.conf" | grep ^dbname | tr -s ' ' | cut -d ' ' -f 2)
        cmd="psql -h localhost -U postgres -d $db -c \"$SQL\""
        "$DOCKER_COMPOSE" -f "$DOCKER_COMPOSE_FILE" exec "$DOCKER_DB_SERVICE" bash -c "$cmd"
    fi
done
