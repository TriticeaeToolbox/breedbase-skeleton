#! /bin/bash

#
# FIX PERMISSIONS
# This script will fix various file and directory permissions on 
# each of the web instances
#

BB_HOME="$1"

"$BB_HOME/bin/update" --setup

exit 0
