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

# PSQL location
PSQL=$(which psql)


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


# Get postgres password from user
read -sp "Postgres password: " postgres_pass
echo ""
echo ""


# Process each web instance
for service in "${services[@]}"; do
   if [[ "$service" != "$DOCKER_DB_SERVICE" ]]; then
        echo "... updating $service admin user"

        # Build SQL update
        sql="UPDATE sgn_people.sp_person SET private_email = '$admin_email', password = sgn.crypt('$admin_pass', sgn.gen_salt('bf')), pending_email = NULL, confirm_code = NULL, cookie_string = NULL WHERE username = 'admin';"

        # Update the admin user properties
        db=$(cat "$BB_CONFIG_DIR/$service.conf" | grep ^dbname | tr -s ' ' | cut -d ' ' -f 2)
        PGPASSWORD="$postgres_pass" psql -h localhost -U postgres -d $db -c "$sql"
        if [ $? -ne 0 ]; then exit 1; fi

    fi
done
