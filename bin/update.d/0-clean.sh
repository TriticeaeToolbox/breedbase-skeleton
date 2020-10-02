#! /bin/bash

#
# CLEAN
# This will stop and remove any existing T3/Breedbase Docker containers
#

BB_HOME="$1"
BREEDBASE="$BB_HOME/bin/breedbase"

echo "==> Removing existing T3/Breedbase containers..."
"$BREEDBASE" clean
