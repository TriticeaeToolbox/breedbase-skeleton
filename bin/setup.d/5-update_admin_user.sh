#! /bin/bash

#
# UPDATE ADMIN USER
# This script will update the admin user of each instance
# - update the password and email of the account
#

BB_HOME="$1"
DOCKER_COMPOSE_FILE="$BB_HOME/docker-compose.yml"
BB_CONFIG_DIR="$BB_HOME/config/"

# Docker compose location
DOCKER_COMPOSE=$(which docker-compose)
DOCKER_DB_SERVICE="breedbase_db"

# Get the defined web services
mapfile -t services <<< $("$DOCKER_COMPOSE" -f "$DOCKER_COMPOSE_FILE" config --services)


echo "==> Updating admin website user..."


# Get admin password
echo "Each T3/Breedbase website instance has an admin user that is given curator privileges."
read -sp "New admin password: " admin_pass
echo ""
read -sp "Confirm admin password: " admin_pass_2
echo ""

# Confirm admin password
if [[ $admin_pass != $admin_pass_2 ]]; then
    echo "ERROR: admin passwords do not match!"
    exit 1
fi

# Get the admin email
echo ""
echo "Each T3/Breedbase website account needs to have an email address associated with it:"
read -p "New admin email: " admin_email
echo ""


# Process each web instance
for service in "${services[@]}"; do
   if [[ "$service" != "$DOCKER_DB_SERVICE" ]]; then
        echo "... updating $service admin user"

        # Get the DB Name for the service
        db=$(cat "$BB_CONFIG_DIR/$service.conf" | grep ^dbname | tr -s ' ' | cut -d ' ' -f 2)

        # Update the admin user properties
        sql="UPDATE sgn_people.sp_person SET private_email = '$admin_email', password = sgn.crypt('$admin_pass', sgn.gen_salt('bf')), pending_email = NULL, confirm_code = NULL, cookie_string = NULL WHERE username = 'admin';"
        cmd="psql -h localhost -U postgres -d $db -c \"$sql\""
        "$DOCKER_COMPOSE" -f "$DOCKER_COMPOSE_FILE" exec "$DOCKER_DB_SERVICE" bash -c "$cmd"
    fi
done
