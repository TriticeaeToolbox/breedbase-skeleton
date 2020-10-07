#! /bin/bash

#
# FIX DATABASE PERMISSIONS
# This script will fix various database permissions for the web_usr user
#

BB_HOME="$1"
BREEDBASE="$BB_HOME/bin/breedbase"
DOCKER_COMPOSE_FILE="$BB_HOME/docker-compose.yml"
BB_CONFIG_DIR="$BB_HOME/config/"

# SQL to fix Database Permissions
SQL_URL="https://raw.githubusercontent.com/TriticeaeToolbox/loading-scripts/master/sql/web_usr_grants.sql"
SQL=$(curl -s "$SQL_URL")

# Docker compose location
DOCKER_COMPOSE=$(which docker-compose)
DOCKER_DB_SERVICE="breedbase_db"


# Get the defined web services
mapfile -t services <<< $("$DOCKER_COMPOSE" -f "$DOCKER_COMPOSE_FILE" config --services)


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
