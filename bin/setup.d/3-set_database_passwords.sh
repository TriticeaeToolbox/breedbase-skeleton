#! /bin/bash

#
# SET DATABASE PASSWORDS
# This script will prompt the user for new postgres and web_usr passwords
# It will update the passwords in the postgres database
# It will also update the web_usr passwords in the config files
#

BB_HOME="$1"
BB_CONFIG_DIR="$BB_HOME/config/"
DOCKER_COMPOSE_FILE="$BB_HOME/docker-compose.yml"

# Docker compose location
DOCKER_COMPOSE=$(which docker-compose)
DOCKER_DB_SERVICE="breedbase_db"

# Initial postgres password
INITIAL_POSTGRES_PASSWORD="postgres"


echo "==> Setting Database Passwords..."

# Get postgres password
echo "The default password for the postgres user is '$INITIAL_POSTGRES_PASSWORD' and should be changed"
read -sp "New postgres password: " postgres_pass
echo ""
read -sp "Confirm postgres password: " postgres_pass_2
echo ""

# Confirm postgres password
if [[ $postgres_pass != $postgres_pass_2 ]]; then
    echo "ERROR: postgres passwords do not match!"
    exit 1
fi

# Get the web_usr password
echo ""
echo "The websites access the database using the 'web_usr' password which has not been set"
read -sp "New web_usr password: " webusr_pass
echo ""
read -sp "Confirm web_usr password: " webusr_pass_2
echo ""

# Confirm web_usr password
if [[ $webusr_pass != $webusr_pass_2 ]]; then
    echo "ERROR: web_usr passwords do not match!"
    exit 1
fi


# Update the postgres passwords
echo ""
echo "==> Updating the web_usr password..."
sql="ALTER USER web_usr WITH PASSWORD '$webusr_pass';"
cmd="psql -h localhost -U postgres -d postgres -c \"$sql\""
"$DOCKER_COMPOSE" -f "$DOCKER_COMPOSE_FILE" exec "$DOCKER_DB_SERVICE" bash -c "$cmd"

echo "==> Updating the postgres password..."
sql="ALTER USER postgres WITH PASSWORD '$postgres_pass';"
cmd="psql -h localhost -U postgres -d postgres -c \"$sql\""
"$DOCKER_COMPOSE" -f "$DOCKER_COMPOSE_FILE" exec "$DOCKER_DB_SERVICE" bash -c "$cmd"


# Update the config files
echo ""
echo "==> Updating the web_usr password in the config files..."
for config in "$BB_CONFIG_DIR/"*.conf; do
    echo "... Updating config file [$(basename $config)]..."
    sed -i "s/^dbpass <replace>/dbpass $webusr_pass/g" $config
done
