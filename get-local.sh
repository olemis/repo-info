#!/bin/bash

# script to retrieve the local metadata of a docker image
# author Pavel Milanes Costa / pavelmc@github.com

set -eo pipefail
trap 'echo >&2 Ctrl+C captured, exiting; exit 1' SIGINT

# vars
image=$1
tag="$2"
registry_URL="$3"

# Entry point of the script.
# It makes sure that the user supplied the right amount of arguments 
# (image_name[:tag] and image_URL) and then performs the main workflow:
#       1.      determine if has tag and append :latest if not
#       2.      pull the image
#       3.      get the info from the image
main() {
	check_args "$@"

    echo "Ready to process (local) '$image:$tag'" >&2

    # pulling the image
    # docker pull $repo:$tag

    parse_data
}

# Makes sure that we provided (from the cli) enough arguments.
check_args() {
  if (($# != 3)); then
    echo "Error:
    Three arguments must be provided - $# provided.
  
    Usage:
      ./$0 <local_image> <tag> <registry_URL>
      
	Aborting." >&2
    exit 1
  fi
}

# Parse the data from the local image and get it out
parse_data() {
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

# Run the entry point with the CLI arguments as a list of words as supplied.
main "$@"