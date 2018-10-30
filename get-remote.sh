#!/bin/bash

# script to retrieve the remote metadata of a docker repo
# author Pavel Milanes Costa / pavelmc@github.com

# set -eo pipefail
# trap 'echo >&2 Ctrl+C captured, exiting; exit 1' SIGINT

# local temp vars
repo_manifest=$(mktemp)
repo_config=$(mktemp)

# vars
image=""
tag=""
token=""

# Address of the registry that we'll be performing the inspections against.
# This is necessary as the arguments we supply to the API calls don't include 
# such address (the address is used in the url itself).
# If you use the docker hub, this is fine, if you use a private registry you need
# to modify it (just the fqdn of the registry, without the protocol) 
# fixed use default CDN address (watch out for the -L with curl!)
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
# (image_name and image_tag) and then performs the main workflow:
#       1.      get the auth tocken to access the img on the registry
#       2.      retrieve the image digest
#       3.      retrieve the configuration for that digest.
main() {
	check_args "$@"

	image=$1
	tag=$2

	#  TODO test this online with a private image
	local token=$(get_token $image $tag)
	local digest=$(get_digest)
	get_image_configuration $digest

	# parse the obtained data
	parse_data
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
		echo REALM is $REALM >&2
		echo SERVICE is $SERVICE >&2
		echo SCOPE is $SCOPE >&2
		echo "Got a Valid Auth-token" >&2
		local TOKEN="`curl -sLG "$REALM?service=$SERVICE&scope=$SCOPE"`"
		IFS=\" read _ _ _ TOKEN _ <<<"$TOKEN"
	else
		# no valid answer
		echo "No valid answer, exit" >&2
		exit 1
	fi
}


# Retrieve the digest ffor the repository image
get_digest() {
	URI="$REGISTRY_ADDRESS/$image/manifests/$tag"

	# get manifest
	local manifest=$(
		curl -sLG \
		--header "Accept: $ENCODING" \
		--header "Authorization: Bearer $token" \
		"$URI"
	)

	# dump to a file for debug purposes
	echo $manifest > $repo_manifest
	
	# real output
	echo $manifest | jq -r '.config.digest'
}


# Retrieves the image configuration from a given digest.
# See more about the endpoint at:
# https://docs.docker.com/registry/spec/api/#pulling-a-layer
get_image_configuration() {
	local URI="$REGISTRY_ADDRESS/$image/blobs/$1"
	echo "URI=$URI"

	local digest_config=$(
		curl -vLG \
		--header "Accept: $ENCODING" \
		--header "Authorization: Bearer $token" \
		"$URI"
	)
		
	# dumping the digest config
	echo $digest_config > $repo_config

	# DEBUG
	echo $digest_config >&2
}


# Parse the obtained data, will parse manifest and repo-config and build
# the $output that will be moved to $tag.md in the remote directory 
parse_data() {
	# defaults

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


# Run the entry point with the CLI arguments as a list of words as supplied.
main "$@"

# clean the temp files
rm $repo_manifest
rm $repo_config
