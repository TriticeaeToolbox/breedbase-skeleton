#! /bin/bash

#
# DEV SETUP
# This script will setup a new dev instance and add it to the docker-compose.yml file
# It will use the specified template as the base of the dev instance, copying its
# configuration files and using its mount points.
#
# Arguments:
#   1: BB_HOME - the path to the breedbase home directory
#   2: TEMPLATE - the name of the breedbase service to use as a template
#   3: DEV_NAME - (optional) the name of the new dev instance (Default: breedbase_dev_$TEMPLATE)
#

BB_HOME="$1"
TEMPLATE="$2"
if [ -z "$TEMPLATE" ]; then
    echo "ERROR: The template service name must be provided!"
    exit 1
fi
DEV_NAME=${3:-breedbase_dev_"$TEMPLATE"}
DEV_SERVICE=${DEV_NAME#breedbase_};


# Path to breedbase docker compose file
DOCKER_COMPOSE_FILE="$BB_HOME/docker-compose.yml"

# Path to Docker binaries
DOCKER="$(which docker)"
DOCKER_COMPOSE="$(which docker-compose)"


# Dev Config Files
TEMPLATE_SGN_CONF="$BB_HOME"/config/$TEMPLATE.conf
DEV_SGN_CONF="$BB_HOME"/config/"$DEV_SERVICE".conf
TEMPLATE_MASON_CONF="$BB_HOME"/config/$TEMPLATE.mas
DEV_MASON_CONF="$BB_HOME"/config/"$DEV_SERVICE".mas

# Dev Repos
SGN_REPO="git@github.com:TriticeaeToolbox/sgn.git"
SGN_BRANCH="t3/master"
SGN_DIR="$BB_HOME"/repos/sgn
MASON_REPO="git@github.com:TriticeaeToolbox/mason.git"
MASON_BRANCH="$TEMPLATE"
MASON_DIR="$BB_HOME"/repos/mason


# Check if the service already exists
echo "Checking if dev service already exists [$DEV_SERVICE]..."
exists=$(cat "$DOCKER_COMPOSE_FILE" | grep " *# *start $DEV_SERVICE")
if [ $? -eq 0 ]; then
    echo "ERROR: The dev service already exists! [$DEV_SERVICE]"
    exit 1
fi

# Check if the template service exists
echo "Checking if template service exists [$TEMPLATE]..."
exists=$(cat "$DOCKER_COMPOSE_FILE" | grep " *# * start $TEMPLATE")
if [ $? -eq 1 ]; then
    echo "ERROR: The template service does not exist! [$TEMPLATE]"
    exit 1
fi

# Ensure the dev repos exist
echo "Checking if SGN repo exists [$SGN_DIR]..."
if [ ! -d "$SGN_DIR" ]; then
    echo "WARNING: SGN repo ($SGN_DIR) does not exist"
    read -p "Do you want to clone the sgn repo ($SGN_REPO [$SGN_BRANCH])? (Y/n) " -r
    if [[ $REPLY =~ ^[Nn][Oo]?$ ]]; then
        echo "ERROR: The sgn repo is required! [$SGN_DIR]"
        exit 1
    else
        mkdir -p "$SGN_DIR"
        git clone --branch "$SGN_BRANCH" "$SGN_REPO" "$SGN_DIR"
    fi
fi
echo "Checking is mason repo exists [$MASON_DIR]..."
if [ ! -d "$MASON_DIR" ]; then
    echo "WARNING: mason repo ($MASON_DIR) does not exist"
    read -p "Do you want to clone the mason repo ($MASON_REPO [$MASON_BRANCH])? (Y/n) " -r
    if [[ $REPLY =~ ^[Nn][Oo]?$ ]]; then
        echo "ERROR: The mason repo is required! [$MASON_DIR]"
        exit 1
    else
        mkdir -p "$MASON_DIR"
        git clone --branch "$MASON_BRANCH" "$MASON_REPO" "$MASON_DIR"
    fi
fi


# Copy the template config files
echo "Checking if sgn conf file exists [$DEV_SGN_CONF]..."
if [ -f "$DEV_SGN_CONF" ]; then
    echo "WARNING: the sgn conf file ($DEV_SGN_CONF) already exists"
    read -p "Do you want to replace the file? (y/N) " -r
    if [[ $REPLY =~ ^[Yy][Ee]?[Ss]?$ ]]; then
        rm "$DEV_SGN_CONF"
        cp "$TEMPLATE_SGN_CONF" "$DEV_SGN_CONF"
    fi
else
    cp "$TEMPLATE_SGN_CONF" "$DEV_SGN_CONF"
fi

echo "Checking if mason conf file exists [$DEV_MASON_CONF]..."
if [ -f "$DEV_MASON_CONF" ]; then
    echo "WARNING: the mason conf file ($DEV_MASON_CONF) already exists"
    read -p "Do you want to replace the file? (y/N) " -r
    if [[ $REPLY =~ ^[Yy][Ee]?[Ss]?$ ]]; then
        rm "$DEV_MASON_CONF"
        cp "$TEMPLATE_MASON_CONF" "$DEV_MASON_CONF"
    fi
else
    cp "$TEMPLATE_MASON_CONF" "$DEV_MASON_CONF"
fi


# Copy the template yaml definition
yaml=$(sed -n "/^ *# *start $TEMPLATE/,/^ *# *end $TEMPLATE/p" "$DOCKER_COMPOSE_FILE")

# Create the dev yaml definition
yaml=$(echo "$yaml" | sed -E "s/^( *)# *start $TEMPLATE/\1# start $DEV_SERVICE/g")
yaml=$(echo "$yaml" | sed -E "s/^( *)# *end $TEMPLATE/\1# end $DEV_SERVICE/g")
yaml=$(echo "$yaml" | sed -E "s/^( *)$TEMPLATE:$/\1$DEV_SERVICE:/g")
yaml=$(echo "$yaml" | sed -E "s/^( *)container_name:.*/\1container_name: $DEV_NAME/g")
yaml=$(echo "$yaml" | sed -E "s/^( *)- *([0-9]+):8080$/\1- 1\2:8080/g")

# update port
# update .conf file
# update .mas file
# add sgn repo
# add mason repo

echo "$yaml"

# Add yaml definition to docker-compose file


# # Run the image
# echo "Building and starting $DEV_NAME container..."
# "$DOCKER" run -d -p 8088:8080 \
#     --name "$DEV_NAME" \
#     --label "org.breedbase.type=breedbase_web" \
#     --network="breedbase_default" \
#     -v "$SGN_DIR":/home/production/cxgn/sgn \
#     -v "$MASON_DIR":"/home/production/cxgn/$TEMPLATE" \
#     -v "$BB_HOME"/mnt/$TEMPLATE/archive:/home/production/archive \
#     -v "$BB_HOME"/mnt/$TEMPLATE/public:/home/production/public \
#     -v "$BB_HOME"/mnt/$TEMPLATE/submissions:/home/production/submissions \
#     -v "$DEV_SGN_CONF":/home/production/cxgn/sgn/sgn_local.conf \
#     -v "$DEV_MASON_CONF":/home/production/cxgn/$TEMPLATE/mason/instance/properties.mas \
#     -v "$BB_HOME"/mnt/blast_databases/$TEMPLATE:/home/production/cxgn_blast_databases \
#     "$DEV_NAME":latest