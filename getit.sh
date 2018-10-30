#!/bin/bash

# A scripts to create/update the local metadata of 
# a docker image & repository (aka repo-info metadata)
# Author Pavel Milanes Costa / pavelmc@github.com
# 
# Parameters are as follows
# 1 - local image name (& optional tag name)
# 2 - [optional] remote image name in the registry 
#     (usually the same as the image but can be different in some cases)
# 
# For this script to work the image in the repository must be public
# We asumed the local tag = remote tag. 
# 
# This scripts asumes you are using hub.docker.com services 

# set -eo pipefail
# trap 'echo >&2 Ctrl+C captured, exiting; exit 1' SIGINT

# vars
local_image=""
local_tag=""
remote_image=""
remote_tag=""
ripath=$(pwd)/repo-info
URI=""
imagetagmd=""
token=""
repo_config=$(mktemp)

# Global constants
readonly REGISTRY_ADDRESS="https://registry.hub.docker.com/v2" 
readonly ENCODING="application/vnd.docker.distribution.manifest.v2+json"

# if you are behind a http proxy uncoment and modify as needed
# export http_proxy="http://localhost:8118/"
# export https_proxy="http://localhost:8118/"

# shot to warn about jq, sed & cut absence on the system
jq --help &> /dev/null
sed --help &> /dev/null
cut --help &> /dev/null

# Entry point of the script.
# It makes sure that the user supplied the right amount of arguments 
# (local_image_name[:tag], registry_image_name, and URL_registy)
# and then performs the main workflow:
#       1.      create/updates the README.MD
#       2.      create/updates the local directory
#       3.      create/updates the remote directory
main() {
	check_args "$@"

    # at this point we have loaded this vars on the environment
    # - remote_image
    # - local_image

    # detect the use of tags
    get_image_tag $local_image "local"
	get_image_tag $remote_image "remote"
    
    # setting the remote address of the repository
    URI="https://hub.docker.com/r/$remote_image"

    # title for the README.md
    imagetagmd='`'"$local_image:$tag"'`'

    # build the README.md
    readme

    # build the remote data
    remote_data

    exit 0

    # build the local data
    local_data
}

# Makes sure that we provided (from the cli) enough arguments.
check_args() {
	if (($# != 1)); then
		echo "Error:
		At least two arguments must be provided - $# provided.

		Usage:
		$0 <local_image[:tag]> [remote_image[:tag]]

		Aborting." >&2
		exit 1
	fi

    # detect if we have a third argument
    if [ ! "$3" == "" ] ; then
        # local != remote, note it to the user
        echo "Notice: You provided a different name for the registry image."
        remote_image=$2
    else
        # same name
        remote_image=$1
    fi

    # local_image
    local_image=$1

	echo "Ready to process the repo-info for '$local_image => $remote_image'." >&2
}


# Get image tag, it will take the image name and/or tag and set it
# on the correct environment vars
get_image_tag() {
	# local vars
	local image=""
	local tag=""

    if [ "$(echo $1 | grep ':')" == "" ] ; then
        # no tag :latest
        image="$1"
        tag="latest"
    else 
        # has tag
        image="$(
            echo $1 |
            cut -d ":" -f1
        )"
        tag="$(
            echo $1 |
            cut -d ":" -f2
        )"
    fi

	# local or remote
	if [ "$2" == "local" ] ; then
		# process local image
		local_image=$image
		local_tag=$tag
	else
		# process remote image
		remote_image=$image
		remote_tag=$tag
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

This directory contains additional information about the published artifacts of [the $imagetagmd image]($URI).

-   [the \`remote\` directory](remote/):

   -   Gathered from the Docker Hub/Registry API
   -   Manifest data, platform, layers, exposed ports, dockerfile recipe...
   -   environment variables, dates, etc.

-   [the \`local\` directory](local/):

   -   Inspected from the image on-disk after it is pulled
   -   Image ID, creation date, virtual size, architecture, environment and entry point

EOF
}


# Retrieves the auth token
# It works only for public accessible images
# You must pass:
# 	- repository name (library/ubuntu|skycoin/skycoin)
#	- tag for this repository (latest|develop)
get_token() {
	local image="$1"
	local tag="$2"
	local URI="$REGISTRY_ADDRESS/$image/manifests/$tag"

	# first failed try, to capture real, dervice & scope
	local MANIFEST="`curl -skLG -o /dev/null -D- $URI`"
	local CHALLENGE="`grep "Www-Authenticate" <<<"$MANIFEST"`"

	# Check for a valid answer
	if [[ CHALLENGE ]]; then
		IFS=\" read _ REALM _ SERVICE _ SCOPE _ <<<"$CHALLENGE"
		local TOKEN="`curl -sLG "$REALM?service=$SERVICE&scope=$SCOPE"`"
		IFS=\" read _ _ _ TOKEN _ <<<"$TOKEN"
		# Real output
		echo $TOKEN
	else
		# no valid answer
		echo "No valid answer, exit" >&2
		exit 1
	fi
}


# Retrieve the digest for the repository image
# just one argument, the token
get_digest() {
    local image="$1"
	local tag="$2"
	URI="$REGISTRY_ADDRESS/$image/manifests/$tag"

	# get manifest
	local manifest=$(
		curl -sLG \
		--header "Accept: $ENCODING" \
		--header "Authorization: Bearer $token" \
		"$URI"
	)
	
	# real output
	echo $manifest | jq -r '.config.digest'
}


# Retrieves the image configuration from a given digest.
# See more about the endpoint at:
# https://docs.docker.com/registry/spec/api/#pulling-a-layer
# will put data in a local file 
get_image_configuration() {
    local image="$1"
	local digest="$2"
	local token="$3"
	local URI="$REGISTRY_ADDRESS/$image/blobs/$digest"

	curl -sLG --header "Accept: $ENCODING" \
		--header "Authorization: Bearer $token" \
		"$URI" > $repo_config

}


# Parse the obtained data
# the output that will be put in $tag.md in the remote directory
parse_data() {
	# defaults
	local image="$1"
	local tag="$2"
	local digest=$3

	# parsing...
	os=$(
		cat $repo_config |
		jq -r '.os'
	)

	arch=$(
		cat $repo_config |
		jq -r '.architecture'
	)

	layers=$(
		cat $repo_config |
		jq -r '.rootfs.diff_ids' |
		grep ':' |
		cut -d '"' -f2
	)

	ports=$(
		cat $repo_config |
		jq -r '.container_config.ExposedPorts' |
		grep ':' |
		cut -d '"' -f2
	)

	dockerfile=$(
		cat $repo_config |
		jq -r '.history | .[] | .created, .created_by' |
		sed s/"\/bin\/sh -c #(nop) "/""/g |
		sed s/"$(date +%Y)"/"# $(date +%Y)"/g
	)

	# default output
	echo '# `'"$image:$tag"'`'
	echo ""
	echo '```console'
	echo "$ docker pull $image@$digest"
	echo '```'
	echo ""
	echo '- Manifest MIME: `'"$ENCODING"'`'
	echo ""
	echo "- Platform: "
	echo "	- $os, $arch"
	echo ""
	echo "- Layers:"
	for l in $layers ; do
		echo "	- $l" 
	done
	echo ""
	echo "- Exposed Ports:"
	for p in $ports ; do
		echo "	- $p" 
	done
	echo ""
	echo '```dockerfile'
	echo "$dockerfile"
	echo '```'
	echo ""
}


# build the remote data and put it on where it belongs
get_remote_data() {
	# The hard work goes here
	token=$(get_token $remote_image $remote_tag)
	digest=$(get_digest $remote_image $remote_tag)
	get_image_configuration $remote_image $digest $token

	# parse the obtained data
	parse_data $remote_image $remote_tag $digest

    # erase trash
    rm $repo_config
}


# Create the remote structure and get the data out
remote_data() {
    # check if the remote directory is not there to create it
    if [ ! -d $ripath/remote ] ; then
        mkdir $ripath/remote
    fi

	# output to file
    get_remote_data > "$ripath/remote/$remote_tag.md"
}

# --------------------------------------------------





# Create/update the local structure
local_data() {
    # check if the local directory is not there to create it
    if [ ! -d $ripath/local ] ; then
        mkdir $ripath/local
    fi

    ./get-local.sh $local_image $tag $registry_URL > $ripath/local/$tag.md
}


# Run the entry point with the CLI arguments as a list of words as supplied.
main "$@"

# all goes well
echo "Done."