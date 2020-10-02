#! /bin/bash

#
# FIX PERMISSIONS
# This script will fix various file and directory permissions on 
# each of the web instances
#

BB_HOME="$1"
BREEDBASE="$BB_HOME/bin/breedbase"
DOCKER_COMPOSE_FILE="$BB_HOME/docker-compose.yml"

# Define the names of the web services to process
WEB_INSTANCES=("avena" "hordeum" "triticum")

# Docker compose location
DOCKER_COMPOSE=$(which docker-compose)



# Process each web instance
echo "==> FIXING PERMISSIONS ON WEB INSTANCES..."
for instance in ${WEB_INSTANCES[@]}; do
    echo "... fixing $instance instance"

    cmd="chown -R www-data:www-data /export/prod/tmp/$instance-site/mason"

    "$DOCKER_COMPOSE" -f "$DOCKER_COMPOSE_FILE" exec "$instance" bash -c "$cmd"
done
