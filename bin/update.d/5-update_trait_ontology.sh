#! /bin/bash

#
# UPDATE TRAIT ONTOLOGY
# This script will reload the trait ontology with the latest version
# from the obo file in the sgn repository
#

BB_HOME="$1"
BREEDBASE="$BB_HOME/bin/breedbase"
DOCKER_COMPOSE_FILE="$BB_HOME/docker-compose.yml"

# Docker compose location
DOCKER_COMPOSE=$(which docker-compose)
DOCKER_DB_SERVICE="breedbase_db"

# Get the defined web services
mapfile -t services <<< $("$DOCKER_COMPOSE" -f "$DOCKER_COMPOSE_FILE" config --services)


echo "==> Updating the Trait Ontology..."


# Get postgres password from user
read -sp "Postgres password: " postgres_pass
echo ""

# Process each web instance
for service in "${services[@]}"; do
   if [[ "$service" != "$DOCKER_DB_SERVICE" ]]; then
        echo "... updating $service ontology"
        
        # Command(s) to update the trait ontology
        obo="/home/production/cxgn/sgn/ontology/$service.obo"

        # Get ontology file properties
        obo_s=$("$DOCKER_COMPOSE" -f "$DOCKER_COMPOSE_FILE" exec "$service" bash -c "cat \"$obo\" | grep ^ontology: | cut -d ' ' -f 2" | tr -d '\r')
        obo_n=$("$DOCKER_COMPOSE" -f "$DOCKER_COMPOSE_FILE" exec "$service" bash -c "cat \"$obo\" | grep ^default-namespace: | cut -d ' ' -f 2" | tr -d '\r')

        # Build command to run chado scripts
        cmd="cd  /home/production/cxgn/Chado/chado/bin;
perl ./gmod_load_cvterms.pl -H breedbase_db -D cxgn_$service -d Pg -r postgres -p \"$postgres_pass\" -s $obo_s -n $obo_n -uv \"$obo\";
perl ./gmod_make_cvtermpath.pl -H breedbase_db -D cxgn_$service -d Pg -u postgres -p \"$postgres_pass\" -c $obo_n -v;"

        "$DOCKER_COMPOSE" -f "$DOCKER_COMPOSE_FILE" exec "$service" bash -c "$cmd"
    fi
done