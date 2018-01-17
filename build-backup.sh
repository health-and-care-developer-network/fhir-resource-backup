#!/bin/bash

# Usage:
# build.sh registryhostname tagname

REGISTRY_HOST=$1
IMAGE_NAME=fhir-profile-backup
TAG_NAME=$2

REGISTRY_URL=$REGISTRY_HOST:5000

if [ -z $REGISTRY_HOST ]
then
  REGISTRY_PREFIX=""
else
  REGISTRY_PREFIX="--tlsverify -H $REGISTRY_HOST:2376"
fi

if [ ! -z $TAG_NAME ]
then
  IMAGE_NAME="$IMAGE_NAME:$TAG_NAME"
fi

# Build the image
set -e # Stop on error
docker $REGISTRY_PREFIX build -t $IMAGE_NAME .

if [ ! -z $REGISTRY_HOST ]
then
  docker $REGISTRY_PREFIX tag $IMAGE_NAME $REGISTRY_URL/$IMAGE_NAME
  docker $REGISTRY_PREFIX push $REGISTRY_URL/$IMAGE_NAME
  docker $REGISTRY_PREFIX rmi $IMAGE_NAME
fi
