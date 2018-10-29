#!/bin/bash

# script to retrieve the remote metadata of a docker repo
# author Pavel Milanes Costa / pavelmc@github.com

set -eo pipefail
trap 'echo >&2 Ctrl+C captured, exiting; exit 1' SIGINT

# local temp vars
repo_manifest=$(mktemp)
repo_config=$(mktemp)

# local vars
image=""
tag=""

# Address of the registry that we'll be performing the inspections against.
# This is necessary as the arguments we supply to the API calls don't include 
# such address (the address is used in the url itself).
# If you use the docker hub, this is fine, if you use a private registry you need
# to modify it (just the fqdn of the registry, without the protocol) 
readonly REGISTRY_ADDRESS="${registry-1.docker.io}"

# if you are behind a http proxy uncoment and modify as needed
# export http_proxy="http://localhost:8118/"
# export https_proxy="http://localhost:8118/"

# shot to warn about jq, seed & cut absence on the system
jq --help &> /dev/null
sed --help &> /dev/null
cut --help &> /dev/null

# Entry point of the script.
# It makes sure that the user supplied the right amount of arguments 
# (image_name and image_tag) and then performs the main workflow:
#       1.      get the auth tocken to access the img on the registry
#       2.      retrieve the image digest
#       3.      retrieve the configuration for
#               that digest.
main() {
	check_args "$@"

	image=$1
	tag=$2

	#  TODO test this online with a private image
	local token=$(get_token $image:$tag)
	local digest=$(get_digest $image $tag $token)
	get_image_configuration $image $digest

	# local testing 
	# local digest=$(get_digest $image $tag)
	# get_image_configuration $image $digest

	# parse the obtained data
	parse_data
}


# Retrieves a token that grants access to a private image
# named `image` on registry.docker.io.
# note.:        the user identified by `DOCKER_USERNAME`
#               and `DOCKER_PASSWORD` must have access
#               to the image.
get_token() {
	local image=$1

	# ask for user:password to access the docker image
	echo "As the images in the registry are privated ones you need to supply here"
	echo "A username and password of docker hub in order to get the needed info."
	echo "" 
	read -p "User:" DOCKER_USERNAME
	read -p "Password: " DOCKER_PASSWORD

	curl \
		--silent --anyauth \
		-u "$DOCKER_USERNAME:$DOCKER_PASSWORD" \
		"https://auth.docker.io/token?scope=repository:$image:pull&service=registry.docker.io" \
		| jq -r '.token'
}


# Makes sure that we provided (from the cli) enough arguments.
check_args() {
	if (($# != 2)); then
		echo "Error:
		Two arguments must be provided - $# provided.

		Usage:
		./$0 <image> <tag>

		Aborting." >&2
		exit 1
	fi

	echo "Ready to process (remote) '$1:$2'" >&2
}


# Retrieve the digest, now specifying in the header the token we just received.
# note.:        $token corresponds to the token
#               that we received from the `get_token`
#               call.
# note.:        $image must be the full image name without
#               the registry part, e.g.: `nginx` should
#               be named `library/nginx`.
# TODO: check if the tag is part of the name?
get_digest() {
	local image=$1
	local tag=$2
	local token=$3

	echo "Retrieving image digest.
		IMAGE:  $image
		TAG:    $tag
		TOKEN:  $token
	" >&2

	local manifest=$(
		curl \
		--silent \
		--header "Accept: application/vnd.docker.distribution.manifest.v2+json" \
		"http://$REGISTRY_ADDRESS/v2/$image/manifests/$tag"
	)
		
	# TODO include auth
	# --header "Authorization: Bearer $token" \

	# dump to a file for debug purposes
	echo $manifest > $repo_manifest
	
	# real output
	echo $manifest | jq -r '.config.digest'
}


# Retrieves the image configuration from a given digest.
# See more about the endpoint at:
# https://docs.docker.com/registry/spec/api/#pulling-a-layer
get_image_configuration() {
	local image=$1
	local digest=$2

	local digest_config=$(
		curl \
		--silent \
		--location \
		"http://$REGISTRY_ADDRESS/v2/$image/blobs/$digest"
	)
		
	# dumping the digest config for debug purposes
	echo $digest_config > $repo_config

}


# Parse the obtained data, will parse manifest and repo-config and build
# the $output that will be moved to $tag.md in the remote directory 
parse_data() {
	# defaults
	mime="application/vnd.docker.distribution.manifest.list.v2+json"

	# capturing the data
	# TODO the digest is from maniest.config.digest | repo_config.container
	digest=$(
		cat $repo_manifest |
		jq -r '.config.digest'
	)

	os=$(cat $repo_config |
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
	echo '- Manifest MIME: `'"$mime"'`'
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


# Run the entry point with the CLI arguments as a list of words as supplied.
main "$@"

# clean the temp files
rm $repo_manifest
rm $repo_config
