#!/bin/bash

# Docker Repo-Info Builder (drib)
#
# A scripts to create/update the local metadata of a docker image & repository
# aka: repo-info metadata folders
# 
# Author Pavel Milanes Costa / pavelmc@github.com / stdevPavelmc@github.com
# 
# Parameters are as follows
# 1 - local image name (& optional tag name, will use 'latest' if missing)
# 2 - [optional] remote image name & tag in the registry 
#     (usually the same as the image but can be different in some cases)
# 
# For this script to work the image in the repository must be public
# Watch out! I use the local tag = remote tag. 
# 
# This scripts assumes you are using hub.docker.com services 

set -eo pipefail
trap 'echo >&2 Ctrl+C captured, exiting; exit 1' SIGINT

# vars
local_image=""
local_tag=""
remote_image=""
remote_tag=""
ripath=$(pwd)/repo-info
URI=""
image_md=""
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
main() {
	check_args "$@"

    # at this point we have loaded this vars on the environment
    # - remote_image
    # - local_image

    # detect the use of tags and fill the vars with it
    get_image_tag $local_image "local"
	get_image_tag $remote_image "remote"
    
    # setting the remote address of the repository
    URI="https://hub.docker.com/r/$remote_image"

    # title for the README.md
    image_md='`'"$remote_image"'`'

    # build the README.md
    readme

    # build the remote data
    remote_data

    # build the local data
    local_data


	# all goes well
	echo "All Done, thank you."
}

# Makes sure that we provided (from the cli) enough arguments.
check_args() {
	if (($# != 1)); then
		echo "Error:
		At least two arguments must be provided - $# provided.

		Usage:
		$0 <local_image[:tag]> [remote_image[:tag]]

        Will assume 'latest' for all not declared tags

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
# $image_md repo-info

This directory contains additional information about the published artifacts of [the $image_md image]($URI).

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

		# verbose output
		echo "Got token from: $REALM?service=$SERVICE&scope=$SCOPE" >&2

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

	# parse output
	digest=$(echo $manifest | jq -r '.config.digest')

	# verbose
	echo "Get remote digest: $digest" >&2

	# real output
	echo $digest
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

	# verbose
	echo "Got image config" >&2

}


# Parse the obtained data
# the output that will be put in $tag.md in the remote directory
parse_remote_data() {
	# defaults
	local image="$1"
	local tag="$2"
	local digest=$3

	# verbose
	echo "Parsing remote data to ./repo-info/remote/$tag.md" >&2

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
	parse_remote_data $remote_image $remote_tag $digest

    # erase trash
    rm $repo_config
}


# Create the remote structure and get the data out
remote_data() {
    # check if the remote directory is not there to create it
    if [ ! -d $ripath/remote ] ; then
        mkdir $ripath/remote
    fi

	# User feedback
	echo "Getting remote info..." >&2

	# output to file
    get_remote_data > "$ripath/remote/$remote_tag.md"

	# User feedback
	echo "Done remote." >&2
}


# Parse the data from the local image and get it out
parse_local_data() {
	local image=$1
	local tag=$2

	# verbose
	echo "Parsing local data to ./repo-info/local/$tag.md" >&2

    echo '# `'"$image:$tag"'`'

    # get the virtual size of the image
    size="$(
	    docker inspect -f '{{ .VirtualSize }}' "$image:$tag" | 
        awk '{
            oneKb = 1000;
            oneMb = 1000 * oneKb;
            oneGb = 1000 * oneMb;
            if ($1 >= oneGb) {
                printf "~ %.2f Gb", $1 / oneGb
            } else if ($1 >= oneMb) {
                printf "~ %.2f Mb", $1 / oneMb
            } else if ($1 >= oneKb) {
                printf "~ %.2f Kb", $1 / oneKb
            } else {
                printf "%d bytes", $1
            }
        }'
    )"

    # build the info and put it out
    docker inspect -f '
## Docker Metadata

- Image ID: `{{ .Id }}`
- Created: `{{ .Created }}`
- Virtual Size: '"$size"'
    (total size of all layers on-disk)
- Arch: `{{ .Os }}`/`{{ .Architecture }}`
{{ if .Config.Entrypoint }}- Entrypoint: `{{ json .Config.Entrypoint }}`
{{ end }}{{ if .Config.Cmd }}- Command: `{{ json .Config.Cmd }}`
{{ end }}- Environment:{{ range .Config.Env }}{{ "\n" }}    - `{{ . }}`{{ end }}' "$image:$tag"

    echo ""
}


# build the local data and put it on where it belongs
get_local_data() {
	# verbose
	echo "Pulling the image from docker hub" >&2

    # pulling the image if not local
    docker pull $local_image:$local_tag >&2

	# parse the data
	parse_local_data $local_image $local_tag
}


# Create/update the local structure
local_data() {
    # check if the local directory is not there to create it
    if [ ! -d $ripath/local ] ; then
        mkdir $ripath/local
    fi

	# User feedback
	echo "Getting local info..." >&2

	# output to file
    get_local_data > "$ripath/local/$local_tag.md"

	# User feedback
	echo "Done local." >&2
}


# Run the entry point with the CLI arguments as a list of words as supplied.
main "$@"
