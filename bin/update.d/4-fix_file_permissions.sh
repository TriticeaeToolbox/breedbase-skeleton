#! /bin/bash

#
# FIX FILE PERMISSIONS
# This script will fix various file and directory permissions on 
# each of the web instances
#

BB_HOME="$1"
SERVICE="$2"
BREEDBASE="$BB_HOME/bin/breedbase"
DOCKER_COMPOSE_FILE="$BB_HOME/docker-compose.yml"
BB_CONFIG_DIR="$BB_HOME/config/"

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

# Process each web instance
echo "==> Fixing file permissions on the web instances..."
for service in "${services[@]}"; do
   if [[ "$service" != "$DOCKER_DB_SERVICE" ]]; then
        echo "... fixing $service instance"
        
        # Command(s) to run that fix various file permission problems\
        tmp=$(cat "$BB_CONFIG_DIR/$service.conf" | grep ^tempfiles_base | tr -s ' ' | xargs | cut -d ' ' -f 2)
        archive=$(cat "$BB_CONFIG_DIR/$service.conf" | grep ^archive_path | tr -s ' ' | xargs | cut -d ' ' -f 2)
        submissions=$(cat "$BB_CONFIG_DIR/$service.conf" | grep ^submission_path | tr -s ' ' | xargs | cut -d ' ' -f 2)
        static_content=$(cat "$BB_CONFIG_DIR/$service.conf" | grep ^static_content_path | tr -s ' ' | xargs | cut -d ' ' -f 2)
        cmd="mkdir -p \"$tmp/mason\"; chown -R www-data:www-data \"$tmp/mason\";
chown -R www-data:www-data \"$archive\";
chown -R www-data:www-data \"$submissions\";
mkdir -p \"$static_content/folder\"; chown -R www-data:www-data \"$static_content/folder\""
        "$DOCKER_COMPOSE" -f "$DOCKER_COMPOSE_FILE" exec "$service" bash -c "$cmd"
    fi
done