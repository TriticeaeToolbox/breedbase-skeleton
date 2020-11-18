#! /bin/bash

#
# RESTART
# Stop and remove any existing containers
# Start all specified services
#

BB_HOME="$1"
SERVICE="$2"
BREEDBASE="$BB_HOME/bin/breedbase"

echo "==> Restarting the T3/Breedbase Docker Containers..."
"$BREEDBASE" stop "$SERVICE"
"$BREEDBASE" start "$SERVICE"