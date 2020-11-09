#! /bin/bash

#
# CONFIRM ACCOUNT
# This script will confirm the account of the user on the specified service
#   Arg 1: BB Home directory
#   Arg 2: docker database service name
#   Arg 3: docker web service name
#   Arg 4: user, either the username or user's email
#

# Parse Arguments
BB_HOME="$1"
DB_SERVICE="$2"
SERVICE="$3"
USER="$4"
if [ -z "$SERVICE" ]; then
    echo "ERROR: The service name must be provided!"
    exit 1
fi
if [ -z "$USER" ]; then
    echo "ERROR: The user must be provided!"
    exit 1
fi


# Set Breedbase Paths
BB_CONFIG_DIR="$BB_HOME/config"
DOCKER_COMPOSE_FILE="$BB_HOME/docker-compose.yml"
BB_CONFIG="$BB_CONFIG_DIR/$SERVICE.conf"

# Path to Docker binaries
DOCKER_COMPOSE="$(which docker-compose)"


# Get database name from config file
db=$(cat "$BB_CONFIG" | grep ^dbname | tr -s ' ' | cut -d ' ' -f 2)

# Get the number of user matches
echo "Looking up user $USER [$db]..."
sql="SELECT sp_person_id, last_name, first_name, username, pending_email, disabled FROM sgn_people.sp_person WHERE username = '$USER' OR pending_email = '$USER' OR private_email = '$USER';"
cmd="echo \"$sql\" | psql -h localhost -U postgres -d \"$db\""
"$DOCKER_COMPOSE" -f "$DOCKER_COMPOSE_FILE" exec "$DB_SERVICE" bash -c "$cmd"

# Prompt for user ids
read -p 'Enter the sp_person_id of the account to confirm: ' sp_person_id

# Confirm the account
if [ ! -z $sp_person_id ]; then
    echo "Confirming account $sp_person_id..."
    sql="UPDATE sgn_people.sp_person SET private_email = pending_email, confirm_code = NULL, disabled = NULL WHERE sp_person_id = $sp_person_id;"
    cmd="echo \"$sql\" | psql -h localhost -U postgres -d \"$db\""
    "$DOCKER_COMPOSE" -f "$DOCKER_COMPOSE_FILE" exec "$DB_SERVICE" bash -c "$cmd"
fi