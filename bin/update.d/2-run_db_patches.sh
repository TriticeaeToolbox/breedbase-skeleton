#! /bin/bash

#
# RUN DATABASE PATCHES
# This script will run the database patches for each web instance
#

BB_HOME="$1"
BREEDBASE="$BB_HOME/bin/breedbase"
DOCKER_COMPOSE_FILE="$BB_HOME/docker-compose.yml"
BB_CONFIG_DIR="$BB_HOME/config/"

# Docker compose location
DOCKER_COMPOSE=$(which docker-compose)
DOCKER_DB_SERVICE="breedbase_db"

# Get the defined web services
services=$("$DOCKER_COMPOSE" -f "$DOCKER_COMPOSE_FILE" config --services)
IFS=$'\n' read -d '' -r -a services <<< "$services"


echo "==> Running Database Patches..."


# Get postgres password from user
read -sp "Postgres password: " postgres_pass
echo ""

# Process each web instance
for service in "${services[@]}"; do
   if [[ "$service" != "$DOCKER_DB_SERVICE" ]]; then
        echo "... patching $service instance"

        # Run all DB Patches
        db=$(cat "$BB_CONFIG_DIR/$service.conf" | grep ^dbname | tr -s ' ' | cut -d ' ' -f 2)
        cmd="perl /home/production/cxgn/sgn/db/run_all_patches.pl -u postgres -p \"$postgres_pass\" -h breedbase_db -d $db -e admin"
        "$DOCKER_COMPOSE" -f "$DOCKER_COMPOSE_FILE" exec "$service" bash -c "$cmd"
    fi
done
