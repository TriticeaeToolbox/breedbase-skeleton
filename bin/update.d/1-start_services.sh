#! /bin/bash

#
# START SERVICES
# This script will start the databsae and each of the web instances
#

BB_HOME="$1"
BREEDBASE="$BB_HOME/bin/breedbase"

echo "==> Starting the T3/Breedbase Database and Websites..."
"$BREEDBASE" start

echo "... waiting ..."
sleep 30
