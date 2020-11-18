#! /bin/bash

#
# CLEAN
# This will stop and remove any existing T3/Breedbase Docker containers
#

BB_HOME="$1"
SERVICE="$2"
BREEDBASE="$BB_HOME/bin/breedbase"

if [ -z "SERVICE" ]; then
    echo "==> Removing existing T3/Breedbase containers..."
    "$BREEDBASE" clean "$SERVICE"
fi