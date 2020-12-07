#! /bin/bash

#
# PULL SGN AND MASON REPOS
# This script will pull the latest code into the sgn and mason repos.
# If a service name is specified, just update that service, otherwise 
# update all of the services defined in the docker-compose file.
#   Arg 1: BB Home directory
#   Arg 2: (optional) docker-compose service name
#

# Parse Arguments
BB_HOME="$1"
SERVICE="$2"

# Set Breedbase Paths
DOCKER_COMPOSE_FILE="$BB_HOME/docker-compose.yml"
BB_CONFIG_DIR="$BB_HOME/config/"

# Path to Docker binaries
DOCKER_COMPOSE=$(which docker-compose)
DOCKER_DB_SERVICE="breedbase_db"

# Get list of web services
if [ -z "$SERVICE" ]; then
    services=$("$DOCKER_COMPOSE" -f "$DOCKER_COMPOSE_FILE" config --services)
    IFS=$'\n' read -d '' -r -a services <<< "$services"
else
    services="$SERVICE"
fi

# Update each service
for service in "${services[@]}"; do
    if [[ "$service" != "$DOCKER_DB_SERVICE" ]]; then
        config="$BB_CONFIG_DIR/$service.conf"
        mason_dir=$(cat "$BB_CONFIG_DIR/$service.conf" | grep "^ *add_comp_root" | awk '{$1=$1;print}' | cut -d ' ' -f 2)
        cmd="cd /home/production/cxgn/sgn; git pull; cd \"$mason_dir\"; cd ../; git pull"
        "$DOCKER_COMPOSE" -f "$DOCKER_COMPOSE_FILE" exec "$service" bash -c "$cmd"
    fi
done

