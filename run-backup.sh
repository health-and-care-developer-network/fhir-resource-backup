#!/bin/bash

# Usage:
# build.sh registryhostname targethostname tagname backup_dir backup_file target_dir

REGISTRY_HOST=$1
TARGET_HOST=$2
TAG_NAME=$3

DEFAUT_FILENAME="PROFILE-BACKUP-$(date +%F).zip"
BACKUP_DIR_NAME=${4:-${BACKUP_DIR_NAME:-file-profile-backups}}
BACKUP_FILE_NAME=${5:-${BACKUP_FILE_NAME:-$DEFAUT_FILENAME}}
TARGET_DIR=${6:-${TARGET_DIR:-/docker-data/fhir-profile-backups}}

SHARENAME="applicationbackups"
IMAGE_NAME=fhir-profile-backup
CONTAINER_NAME=${CONTAINER_NAME:-fhir-profile-backup}

if [ ! -z $TAG_NAME ]
then
  IMAGE_NAME="$IMAGE_NAME:$TAG_NAME"
fi

if [ -z $TARGET_HOST ]
then
  TARGET_PREFIX=""
else
  TARGET_PREFIX="--tlsverify -H $TARGET_HOST:2376"
fi

if [ -z $REGISTRY_HOST ]
then
  REGISTRY_PREFIX=""
  SOURCE=$IMAGE_NAME
else
  REGISTRY_PREFIX="--tlsverify -H $REGISTRY_HOST:2376"
  SOURCE=$REGISTRY_HOST:5000/$IMAGE_NAME
fi

if [ $TARGET_DIR = "azure" ]
then
    # A target directory of "azure" was specified, so use the Azure volume driver to create a volume for the backup
    echo "Creating backup volume (using the Azure volume driver)"
    VOLUME=$(docker $TARGET_PREFIX volume create -d azurefile -o share=$SHARENAME)
    DOCKER_VOLUMES="$VOLUME:/backups" 
    EXTRAFLAGS="--userns=host" # The azure volume driver only works if we disable the user namespacing for this container...
else
    # A target directory was provided, use that in preference to the Azure driver
    echo "Using the specified backup directory: $TARGET_DIR"
    DOCKER_VOLUMES="$TARGET_DIR:/backups"
fi

MEMORYFLAG=2g
CPUFLAG=768

echo "Pull and run FHIR resource backup process"
if [ ! -z $REGISTRY_HOST ]
then
  docker $TARGET_PREFIX pull $SOURCE
fi

docker $TARGET_PREFIX run --rm --name $CONTAINER_NAME \
	-v /docker-data/fhir-profiles:/source \
	-v $DOCKER_VOLUMES \
	-e FILENAME=${BACKUP_FILE_NAME} \
	-e BACKUP_DIR_NAME=${BACKUP_DIR_NAME} \
	$EXTRAFLAGS \
	$SOURCE


# Remove the volume again after the backup is complete
if [ $TARGET_DIR = "azure" ]
then
    echo "Removing backup volume"
    #docker $TARGET_PREFIX volume rm $VOLUME
fi

