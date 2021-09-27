#!/usr/bin/bash

dockerfile=$1
img_version=$2
tag=$3
context=$4

error_msg=""

function printArgs () {
    echo Passed Arguments
    echo ================
    echo Dockerfile: $dockerfile
    echo Image Version: $img_version
    echo Image Tag: $tag
    echo Build Context: $context
    echo ""
    return
}

function printUsage () {
    echo "Usage: build DOCKERFILE IMAGE_VERSION IMAGE_TAG CONTEXT"
    echo ""
}

function reportError () {
    echo "Error: $error_msg" >&2
    echo ""
    printUsage
    printArgs
}

if [[ -d $context ]]; then
    echo "About to build image..."
    else
        error_msg="Specified context folder does not exist"
        echo ""
        reportError
        exit 1
fi

if [[ -f $dockerfile ]]; then
    echo docker build -f $dockerfile --build-arg "VERSION=${img_version}" -t $tag $context
    docker build -f $dockerfile --build-arg "VERSION=${img_version}" -t $tag $context
    else
        error_msg="Could not find Dockerfile"
        echo ""
        reportError
        exit 1
fi
