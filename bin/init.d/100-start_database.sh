#! /bin/bash

#
# START DATABASE
# This script will start the T3/Breedbase Database container
# It will then prompt the user to wait unti the database setup has finished
#

BB_HOME="$1"
BREEDBASE="$BB_HOME/bin/breedbase"


echo "==> Starting the T3/Breedbase Database..."
"$BREEDBASE" start db

echo ""
echo "==> Monitor Database log..."
echo "The database is now performing its intial setup..."
echo "Wait until the database setup has finished before continuing"
echo "You can monitor the database log with the following command:"
echo "$BREEDBASE log db"
echo "Continue when you see a line stating that the 'database system is ready to accept connections'"
read -p "Press enter when the database is ready: "
echo ""
