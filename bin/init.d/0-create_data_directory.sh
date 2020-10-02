#! /bin/bash

#
# CREATE DATA DIRECTORY
# This script will create the postgres data directory at:
# $BB_HOME/postgresql/data
#

BB_HOME="$1"
BB_DATA_DIR="$BB_HOME/postgresql/data"


echo "==> Creating Database data directory..."
mkdir -p "$BB_DATA_DIR"
