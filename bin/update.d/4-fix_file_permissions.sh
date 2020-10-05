#! /bin/bash

#
# FIX FILE PERMISSIONS
# This script will fix various file and directory permissions on 
# each of the web instances
#

BB_HOME="$1"
BREEDBASE="$BB_HOME/bin/breedbase"
DOCKER_COMPOSE_FILE="$BB_HOME/docker-compose.yml"

# Docker compose location
DOCKER_COMPOSE=$(which docker-compose)
DOCKER_DB_SERVICE="breedbase_db"

# Get the defined web services
mapfile -t services <<< $("$DOCKER_COMPOSE" -f "$DOCKER_COMPOSE_FILE" config --services)

# Process each web instance
echo "==> FIXING FILE PERMISSIONS ON WEB INSTANCES..."
for service in "${services[@]}"; do
   if [[ "$service" != "$DOCKER_DB_SERVICE" ]]; then
        echo "... fixing $service instance"
        
        # Command(s) to run that fix various file permission problems
        cmd="chown -R www-data:www-data /home/production/tmp/$service-site/mason"
        
        "$DOCKER_COMPOSE" -f "$DOCKER_COMPOSE_FILE" exec "$service" bash -c "$cmd"
    fi
done