#!/bin/bash

# Set of scripts to create/update the local metadata of 
# a docker image & repository (aka repo-info metadata)
# Author Pavel Milanes Costa / pavelmc@github.com
# 
# Parameters are as follows
# 1 - local image name (& optional tag name)
# 2 - remote image name in the registry (usually the same as the image
#     but can be different in some cases)
# 3 - URL of the registry in which the image resides for docs links
# 
# If the image in the repository is private then you will be asked for
# a user:password to access that repository.
# 
# This scripts asumes you are using hub.docker.com 
# & registry.docker.io services

set -eo pipefail
trap 'echo >&2 Ctrl+C captured, exiting; exit 1' SIGINT

# vars
local_image=""
tag=""
remote_image=""
imagetagmd=""
registry_URL=""
ripath=$(pwd)/repo-info

# Entry point of the script.
# It makes sure that the user supplied the right amount of arguments 
# (local_image_name[:tag], registry_image_name, and URL_registy)
# and then performs the main workflow:
#       1.      create/updates the README.MD
#       2.      create/updates the local directory
#       3.      create/updates the remote directory
main() {
	check_args "$@"

    # detect the use of tags
    get_image_tag $1
    
    # setting local vars
    remote_image=$2
    registry_URL=$3

    # title for the README.md
    imagetagmd='`'"$local_image:$tag"'`'

    # build the README.mc
    readme $local_image $tag $registry_URL

    # build the remote data
    remote_data 

    # build the local data
    local_data
}

# Makes sure that we provided (from the cli) enough arguments.
check_args() {
	if (($# != 3)); then
		echo "Error:
		Three arguments must be provided - $# provided.

		Usage:
		./$0 <local_image[:tag]> <remote_image> <registry_URL>

		Aborting." >&2
		exit 1
	fi

	echo "Ready to process the repo-info for '$1 <> $2'" >&2
}

# Get image tag, it will take the image name and/or tag and set it
# on the correct environment vars
get_image_tag() {
    if [ "$(echo $1 | grep ':')" == "" ] ; then
        # no tag :latest
        local_image="$1"
        tag="latest"
    else 
        # has tag
        local_image="$(
            echo $1 |
            cut -d ":" -f1
        )"
        tag="$(
            echo $1 |
            cut -d ":" -f2
        )"
    fi
}

# Build the README.md for the actual data
readme() {
    # check to see if the repo-info folder is there
    if [ ! -d $ripath ] ; then
        mkdir $ripath
    fi

    cat << EOF > $ripath/README.md
# $imagetagmd repo-info

This directory contains additional information about the published artifacts of [the $imagetagmd image]($registry_URL).

-   [the \`remote\` directory](remote/):

   -   Gathered from the Docker Hub/Registry API
   -   Manifest data, platform, layers, exposed ports, dockerfile recipe...
   -   environment variables, dates, etc.

-   [the \`local\` directory](local/):

   -   Inspected from the image on-disk after it is pulled
   -   Image ID, creation date, virtual size, architecture, environment and entry point

EOF
}

# Create/update the local structure
local_data() {
    # check if the local directory is not there to create it
    if [ ! -d $ripath/local ] ; then
        mkdir $ripath/local
    fi

    ./get-local.sh $local_image $tag $registry_URL > $ripath/local/$tag.md
}

# Create the remote structure
remote_data() {
    # check if the remote directory is not there to create it
    if [ ! -d $ripath/remote ] ; then
        mkdir $ripath/remote
    fi

    ./get-remote.sh $remote_image $tag > $ripath/remote/$tag.md
}

# Run the entry point with the CLI arguments as a list of words as supplied.
main "$@"

# all goes well
echo "Done."