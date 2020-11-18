#! /bin/bash

#
# UPDATE TRAIT ONTOLOGY
# This script will reload the trait ontology with the latest version
# from the obo file in the sgn repository
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


echo "==> Updating the Trait Ontology..."


# Get postgres password from user
read -sp "Postgres password: " postgres_pass
echo ""

# Process each web instance
for service in "${services[@]}"; do
   if [[ "$service" != "$DOCKER_DB_SERVICE" ]]; then
        echo "... updating $service ontology"
        
        # Set path to ontology obo file
        obo_file=$(cat "$BB_CONFIG_DIR/$service.conf" | grep ^trait_ontology_obo_file | tr -s ' ' | cut -d ' ' -f 2)
        obo_file_path="/home/production/cxgn/sgn/ontology/$obo_file"

        # Get ontology file properties
        obo_s=$("$DOCKER_COMPOSE" -f "$DOCKER_COMPOSE_FILE" exec "$service" bash -c "cat \"$obo_file_path\" | grep ^ontology: | tr -s ' ' | cut -d ' ' -f 2" | tr -d '\r')
        obo_n=$("$DOCKER_COMPOSE" -f "$DOCKER_COMPOSE_FILE" exec "$service" bash -c "cat \"$obo_file_path\" | grep ^default-namespace: | tr -s ' ' | cut -d ' ' -f 2" | tr -d '\r')

        # Build command to run chado scripts
        db=$(cat "$BB_CONFIG_DIR/$service.conf" | grep ^dbname | tr -s ' ' | cut -d ' ' -f 2)
        cmd="cd  /home/production/cxgn/Chado/chado/bin;
perl ./gmod_load_cvterms.pl -H breedbase_db -D $db -d Pg -r postgres -p \"$postgres_pass\" -s $obo_s -n $obo_n -uv \"$obo_file_path\";
perl ./gmod_make_cvtermpath.pl -H breedbase_db -D $db -d Pg -u postgres -p \"$postgres_pass\" -c $obo_n -v;"

        # Run the Chado scripts
        "$DOCKER_COMPOSE" -f "$DOCKER_COMPOSE_FILE" exec "$service" bash -c "$cmd"


        echo "... checking $service for missing CVTypes ontology"

        # Get cvterm id of required term
        sql="SELECT cvterm_id FROM public.cvterm WHERE cvterm.cv_id = (SELECT cv_id FROM public.cv WHERE cv.name = 'composable_cvtypes') AND cvterm.name = 'trait_ontology';"
        cmd="psql -t -h localhost -U postgres -d $db -c \"$sql\" | tr -d \"[:blank:]\""
        cvterm_id=$("$DOCKER_COMPOSE" -f "$DOCKER_COMPOSE_FILE" exec "$DOCKER_DB_SERVICE" bash -c "$cmd" | tr -d '\r')

        # CV is missing...
        if [[ -z "$cvterm_id" ]]; then

            # SQL to create the ontology
            sql="INSERT into cv (name) values ('composable_cvtypes');
INSERT into dbxref (db_id, accession) select db_id, 'trait_ontology' from db where name = 'null';
INSERT into cvterm (cv_id,name,dbxref_id) select cv_id, 'trait_ontology', dbxref_id from cv join dbxref on true where cv.name = 'composable_cvtypes' and dbxref.accession = 'trait_ontology';
INSERT into dbxref (db_id, accession) select db_id, 'composed_trait_ontology' from db where name = 'null';
INSERT into cvterm (cv_id,name,dbxref_id) select cv_id, 'composed_trait_ontology', dbxref_id from cv join dbxref on true where cv.name = 'composable_cvtypes' and dbxref.accession = 'composed_trait_ontology';
INSERT into dbxref (db_id, accession) select db_id, 'object_ontology' from db where name = 'null';
INSERT into cvterm (cv_id,name,dbxref_id) select cv_id, 'object_ontology', dbxref_id from cv join dbxref on true where cv.name = 'composable_cvtypes' and dbxref.accession = 'object_ontology';
INSERT into dbxref (db_id, accession) select db_id, 'attribute_ontology' from db where name = 'null';
INSERT into cvterm (cv_id,name,dbxref_id) select cv_id, 'attribute_ontology', dbxref_id from cv join dbxref on true where cv.name = 'composable_cvtypes' and dbxref.accession = 'attribute_ontology';
INSERT into dbxref (db_id, accession) select db_id, 'method_ontology' from db where name = 'null';
INSERT into cvterm (cv_id,name,dbxref_id) select cv_id, 'method_ontology', dbxref_id from cv join dbxref on true where cv.name = 'composable_cvtypes' and dbxref.accession = 'method_ontology';
INSERT into dbxref (db_id, accession) select db_id, 'unit_ontology' from db where name = 'null';
INSERT into cvterm (cv_id,name,dbxref_id) select cv_id, 'unit_ontology', dbxref_id from cv join dbxref on true where cv.name = 'composable_cvtypes' and dbxref.accession = 'unit_ontology';
INSERT into dbxref (db_id, accession) select db_id, 'time_ontology' from db where name = 'null';
INSERT into cvterm (cv_id,name,dbxref_id) select cv_id, 'time_ontology', dbxref_id from cv join dbxref on true where cv.name = 'composable_cvtypes' and dbxref.accession = 'time_ontology';"

            # Add the missing ontoloy
            echo "... adding missing CVTypes ontology to $service"
            cmd="psql -h localhost -U postgres -d $db -c \"$sql\""
            "$DOCKER_COMPOSE" -f "$DOCKER_COMPOSE_FILE" exec "$DOCKER_DB_SERVICE" bash -c "$cmd"
        
        fi


        echo "... checking $service if trait ontology is tagged as 'trait_ontology'"

        # get cv id of trait ontology
        sql="SELECT cv_id FROM public.cv WHERE cv.name = '$obo_n';"
        cmd="psql -t -h localhost -U postgres -d $db -c \"$sql\" | tr -d \"[:blank:]\""
        cv_id=$("$DOCKER_COMPOSE" -f "$DOCKER_COMPOSE_FILE" exec "$DOCKER_DB_SERVICE" bash -c "$cmd" | tr -d '\r')

        # Get cvprop id of tagged trait ontology
        sql="SELECT cvprop_id FROM public.cvprop WHERE cv_id = '$cv_id' AND type_id = (SELECT cvterm_id FROM public.cvterm WHERE cv_id = (SELECT cv_id FROM public.cv WHERE name = 'composable_cvtypes') AND name = 'trait_ontology');"
        cmd="psql -t -h localhost -U postgres -d $db -c \"$sql\" | tr -d \"[:blank:]\""
        cvprop_id=$("$DOCKER_COMPOSE" -f "$DOCKER_COMPOSE_FILE" exec "$DOCKER_DB_SERVICE" bash -c "$cmd" | tr -d '\r')

        # CVProp is missing...
        if [[ -z "$cvprop_id" ]]; then

            # SQL to add missing cvprop
            sql="DELETE FROM public.cvprop WHERE type_id = (SELECT cvterm_id FROM public.cvterm WHERE cv_id = (SELECT cv_id FROM public.cv WHERE name = 'composable_cvtypes') AND name = 'trait_ontology');
INSERT INTO public.cvprop (cv_id, type_id) SELECT cv.cv_id AS cv_id, cvterm.cvterm_id AS type_id FROM public.cv JOIN public.cvterm ON (1=1) WHERE cv.name = '$obo_n' AND cvterm.cvterm_id = (SELECT cvterm_id FROM public.cvterm WHERE cv_id = (SELECT cv_id FROM public.cv WHERE name = 'composable_cvtypes') AND name = 'trait_ontology');"

            # Add the missing cvprop
            echo "... adding missing CVProp for $service trait ontology"    
            cmd="psql -h localhost -U postgres -d $db -c \"$sql\""
            "$DOCKER_COMPOSE" -f "$DOCKER_COMPOSE_FILE" exec "$DOCKER_DB_SERVICE" bash -c "$cmd"

        fi
    fi
done