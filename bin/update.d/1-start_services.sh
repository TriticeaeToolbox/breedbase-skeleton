#! /bin/bash

#
# START SERVICES
# This script will start the databsae and each of the web instances
#

BB_HOME="$1"
SERVICE="$2"
BREEDBASE="$BB_HOME/bin/breedbase"

if [ -z "$SERVICE" ]; then
    echo "==> Starting the T3/Breedbase Database and Websites..."
    "$BREEDBASE" start

    echo "... waiting for services to start ..."
    sleep 30
fi
