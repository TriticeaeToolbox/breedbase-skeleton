#! /bin/bash

#
# DEV SETUP
# This script will create a new breedbase web container, duplicated 
# from the specified existing container, to use as a development machine
#

BB_HOME="$1"
TEMPLATE="$2"
if [ -z "$TEMPLATE" ]; then
    echo "ERROR: The template service name must be provided!"
    exit 1
fi


# Path to breedbase docker compose file
DOCKER_COMPOSE_FILE="$BB_HOME/docker-compose.yml"

# Path to Docker binaries
DOCKER="$(which docker)"
DOCKER_COMPOSE="$(which docker-compose)"

# Dev properties
DEV_NAME=${3:-breedbase_dev_"$TEMPLATE"}

# Dev Config Files
DEV_SERVICE=${DEV_NAME#breedbase_};
TEMPLATE_SGN_CONF="$BB_HOME"/config/$TEMPLATE.conf
DEV_SGN_CONF="$BB_HOME"/config/"$DEV_SERVICE".conf
TEMPLATE_MASON_CONF="$BB_HOME"/config/$TEMPLATE.mas
DEV_MASON_CONF="$BB_HOME"/config/"$DEV_SERVICE".mas

# Dev Repos
SGN_REPO="git@github.com:TriticeaeToolbox/sgn.git"
SGN_BRANCH="t3/master"
SGN_DIR=${4:-"$BB_HOME"/repos/sgn}
MASON_REPO="git@github.com:TriticeaeToolbox/mason.git"
MASON_BRANCH="$TEMPLATE"
MASON_DIR=${5:-"$BB_HOME"/repos/mason}


# Check if the dev container already exists
container_hash=$("$DOCKER" ps -a -q -f name="$DEV_NAME")
if [ ! -z $container_hash ]; then
    echo "WARNING: Dev container ($DEV_NAME) already exists"
    read -p "Do you want to use the existing container? " -r
    if [[ $REPLY =~ ^[Yy][Ee]?[Ss]?$ ]]; then
        "$DOCKER" start "$DEV_NAME"
        exit 0
    else
        "$DOCKER" stop "$DEV_NAME"
        "$DOCKER" container rm "$DEV_NAME"
    fi
fi

# Check if the dev image already exists
image_hash=$("$DOCKER" images -q "$DEV_NAME")
if [ ! -z $image_hash ]; then
    echo "WARNING: Dev image ($DEV_NAME) already exists"
    read -p "Do you want to remove the existing image? " -r
    if [[ $REPLY =~ ^[Yy][Ee]?[Ss]?$ ]]; then
        "$DOCKER" image rm "$DEV_NAME"
        image_hash=""
    fi
fi

# Create the image, if it does not exist
if [ -z $image_hash ]; then

    # Ensure the specified template service is created
    template_hash=$("$DOCKER_COMPOSE" -f "$DOCKER_COMPOSE_FILE" ps -q "$TEMPLATE")
    if [ $? -eq 1 ]; then
        echo "ERROR: Template service does not exist"
        exit 1
    fi

    # Duplicate the container
    echo "Duplicating $TEMPLATE container to $DEV_NAME image..."
    "$DOCKER" commit "$template_hash" "$DEV_NAME"

fi


# Ensure the dev repos exist
if [ ! -d "$SGN_DIR" ]; then
    echo "WARNING: SGN repo ($SGN_DIR) does not exist"
    read -p "Do you want to clone the sgn repo ($SGN_REPO [$SGN_BRANCH])? " -r
    if [[ $REPLY =~ ^[Yy][Ee]?[Ss]?$ ]]; then
        mkdir -p "$SGN_DIR"
        git clone --branch "$SGN_BRANCH" "$SGN_REPO" "$SGN_DIR"
    else
        exit 1
    fi
fi
if [ ! -d "$MASON_DIR" ]; then
    echo "WARNING: mason repo ($MASON_DIR) does not exist"
    read -p "Do you want to clone the mason repo ($MASON_REPO [$MASON_BRANCH])? " -r
    if [[ $REPLY =~ ^[Yy][Ee]?[Ss]?$ ]]; then
        mkdir -p "$MASON_DIR"
        git clone --branch "$MASON_BRANCH" "$MASON_REPO" "$MASON_DIR"
    else
        exit 1
    fi
fi


# Copy the template config files
if [ -f "$DEV_SGN_CONF" ]; then
    echo "WARNING: the sgn conf file ($DEV_SGN_CONF) already exists"
    read -p "Do you want to replace the file? " -r
    if [[ $REPLY =~ ^[Yy][Ee]?[Ss]?$ ]]; then
        rm "$DEV_SGN_CONF"
        cp "$TEMPLATE_SGN_CONF" "$DEV_SGN_CONF"
    fi
else
    cp "$TEMPLATE_SGN_CONF" "$DEV_SGN_CONF"
fi

if [ -f "$DEV_MASON_CONF" ]; then
    echo "WARNING: the mason conf file ($DEV_MASON_CONF) already exists"
    read -p "Do you want to replace the file? " -r
    if [[ $REPLY =~ ^[Yy][Ee]?[Ss]?$ ]]; then
        rm "$DEV_MASON_CONF"
        cp "$TEMPLATE_MASON_CONF" "$DEV_MASON_CONF"
    fi
else
    cp "$TEMPLATE_MASON_CONF" "$DEV_MASON_CONF"
fi


# Run the image
echo "Building and starting $DEV_NAME container..."
"$DOCKER" run -d -p 8088:8080 \
    --name "$DEV_NAME" \
    --label "org.breedbase.type=breedbase_web" \
    --network="breedbase_default" \
    -v "$SGN_DIR":/home/production/cxgn/sgn \
    -v "$MASON_DIR":"/home/production/cxgn/$TEMPLATE" \
    -v "$BB_HOME"/mnt/$TEMPLATE/archive:/home/production/archive \
    -v "$BB_HOME"/mnt/$TEMPLATE/public:/home/production/public \
    -v "$BB_HOME"/mnt/$TEMPLATE/submissions:/home/production/submissions \
    -v "$DEV_SGN_CONF":/home/production/cxgn/sgn/sgn_local.conf \
    -v "$DEV_MASON_CONF":/home/production/cxgn/$TEMPLATE/mason/instance/properties.mas \
    -v "$BB_HOME"/mnt/blast_databases/$TEMPLATE:/home/production/cxgn_blast_databases \
    "$DEV_NAME":latest