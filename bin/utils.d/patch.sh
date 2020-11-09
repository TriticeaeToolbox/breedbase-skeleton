#! /bin/bash

#
# RUN DATABASE PATCH
# This script will run a specific set of database patches for 
# the database of the specified web service
#   Arg 1: BB Home directory
#   Arg 2: docker web service name
#   Arg 3: database patch number
#


# Parse Arguments
BB_HOME="$1"
SERVICE="$2"
PATCH="$3"
if [ -z "$SERVICE" ]; then
    echo "ERROR: The service name must be provided!"
    exit 1
fi
if [ -z "$PATCH" ]; then
    echo "ERROR: The database patch number must be provided!"
    exit 1
fi

# Set Breedbase Paths
BB_CONFIG_DIR="$BB_HOME/config"
DOCKER_COMPOSE_FILE="$BB_HOME/docker-compose.yml"
BB_CONFIG="$BB_CONFIG_DIR/$SERVICE.conf"

# Path to Docker binaries
DOCKER_COMPOSE="$(which docker-compose)"
DOCKER="$(which docker)"


# Get database name from config file
db=$(cat "$BB_CONFIG" | grep ^dbname | tr -s ' ' | cut -d ' ' -f 2)

# Get container name of service
container=breedbase_"$SERVICE"
container_hash=$("$DOCKER" ps -q -f name="$container")
if [ ! -z $container_hash ]; then
    CONTAINER="$container"
else
    CONTAINER=$("$DOCKER" inspect -f '{{.Name}}' $("$DOCKER_COMPOSE" ps -q "$SERVICE") | cut -c2-)
fi


# Get postgres password from user
read -sp "Postgres password: " postgres_pass
echo ""


# Find matching database patches
echo "Looking up DB Patch $PATCH [$SERVICE]..."
cmd="find /home/production/cxgn/sgn/db -maxdepth 1 -regex '.*\/0*$PATCH$' -exec echo {} \;"
patch_dir=$("$DOCKER" exec "$CONTAINER" bash -c "$cmd" | tr -d '\r')
if [ -z $patch_dir ]; then
    echo "ERROR: Could not find matching DB Patch [$PATCH]"
    exit 1
fi

# Find patch files
echo "Finding patch files [$patch_dir]..."
cmd="find \"$patch_dir\" -maxdepth 1 -regex '.*\/.*\.pm$' -exec echo {} \;"
patches=$("$DOCKER" exec "$CONTAINER" bash -c "$cmd" | tr -d '\r')
if [ -z "$patches" ]; then
    echo "ERROR: No patch files found [$patch_dir]"
    exit 1
fi

# Run the patch files
echo "Running patches [$db]..."
while IFS= read -r patch; do
    name=$(basename "$patch" .pm)
    echo "...running $name patch"
    cmd="cd \"$patch_dir\"; echo -ne \"postgres\n$postgres_pass\" | mx-run $name -F -H breedbase_db -D \"$db\" -u admin"
    "$DOCKER" exec -t "$CONTAINER" bash -c "$cmd"
done <<< "$patches"
