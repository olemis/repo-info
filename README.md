# Docker Repo-info builder, pure bash for simplicity.

A simple as possible scripts to automate the generation of Docker metadata directory known as "repo-info"

The drib name came from the initials: "Docker repo-info builder"

## How to use it

Are you using GNU/Linux right? (this is linux only, sorry.)

You can follow this simple steps:
* Create the repo-info folder in the place you need it.
* Copy the drib.sh (only this file) to the repo-info folder you just created._(You can do this step by getting the raw file from github, see how below)_
* Change to the created folder and give exec right to the file:

```sh
$ chmod +x drib.sh
```

* Now run it, lets assume that you want to create the metadata folder for the skycoin/skycoindev-cli with the tag develop let's see:

```sh
$ ./drib.sh skycoin/skycoindev-cli:develop
Ready to process the repo-info for 'skycoin/skycoindev-cli => skycoin/skycoindev-cli'.
Getting remote info...
Got token from: https://auth.docker.io/token
Get remote digest: sha256:f078698f17c9fb74151b5e63aa6a959505f27fba1af95378ce760c91f0d7ea2a
Got image config
Parsing remote data to /home/cat/github/repo-info/remote/develop.md
Done remote.
Getting local info...
Pulling the image from docker hub
develop: Pulling from skycoin/skycoindev-cli
Digest: sha256:dc32d9062d9bee86d3d9ad5230ec6022068794af8029c926595892904900b02f
Status: Image is up to date for skycoin/skycoindev-cli:develop
Parsing local data to /home/cat/github/repo-info/local/develop.md
Done local.
All Done, thank you.
```

Now you can check your fs to see the created files/folders, you will have a README.md and two folders named local & remote. Now you can remove the drib.sh file if you like or let it be for future updates.

## Search & process all tags for a given image

Imagine you are the maintainer of a group of docker images for a project in a public repository (Docker Hub, but can be others) with just different tags...

How wonderful will be if you can make the repo-info for all tags in the repository for a given image name?

Wonder no more: move to your desired folder  run it with two special arguments '-a' and your image name (in this case skycoin/skycoindev-cli)

```sh
$ ./drib.sh -a skycoin/skycoindev-cli
Found the following tags:
TAGS: develop dind
Processing tag: develop
Getting remote info...
Got token from: https://auth.docker.io/token
Get remote digest: sha256:f078698f17c9fb74151b5e63aa6a959505f27fba1af95378ce760c91f0d7ea2a
Got image config
Parsing remote data to /home/cat/github/remote/develop.md
Done remote.
Getting local info...
Pulling the image from docker hub
develop: Pulling from skycoin/skycoindev-cli
Digest: sha256:dc32d9062d9bee86d3d9ad5230ec6022068794af8029c926595892904900b02f
Status: Image is up to date for skycoin/skycoindev-cli:develop
Parsing local data to /home/cat/github/local/develop.md
Done local.
All Done, thank you.
Processing tag: dind
Getting remote info...
Got token from: https://auth.docker.io/token
Get remote digest: sha256:059f9228a6dfe11c08e475b383cd851edbbb2d11ee766cc4067e329f3b6ce5c2
Got image config
Parsing remote data to /home/cat/github/remote/dind.md
Done remote.
Getting local info...
Pulling the image from docker hub
dind: Pulling from skycoin/skycoindev-cli
Digest: sha256:0fe7e94109f07dbb6d2840e13bb660be50cef87b11999c47354ec2c36945423c
Status: Image is up to date for skycoin/skycoindev-cli:dind
Parsing local data to /home/cat/github/local/dind.md
Done local.
All Done, thank you.
```

## Troubles?

If you get in troubles with it or manages to crash it, please [search your problem to see if it was already reported](https://github.com/simelo/repo-info-tools/issues) and, if not, then [file an issue](https://github.com/simelo/repo-info-tools/issues/new) .

## Good to Know

### The basic syntax of the command line is

```sh
$ ./drib.sh <local_image[:local_tag]> [remote_image[:remote-tag]]
```

As you see the only needed parameter is the local image, the tags are assumes as 'latest' is not specified.

Also note that you can run it with different local and remote image names and also tags.

### The search and process all tags command line syntax is like this

```sh
$ ./drib.sh -a <repository>
```

In this case all options are mandatory and 'repository' refers to a docker hub registry entry like 'library/registry' or 'skycoin/skycoin'

### Search and process all tags with a filter option syntax is like this

```sh
$ ./drib.sh -a <repository> -f "(^latest.*$)|(^develop.*$)|(^release.*$)|(^arm.*$)"
```

Where the argument of the '-f' switch is a regex expression ready to be processed by the `grep -E` command; see the man for grep to know more.

The power of regexes will let you make your particular magic on filtering.

### Getting the file, fast way

You can fetch & setup the file in just one line with this command: (You need to move to the folder where you want to run it before)

```sh
$ curl -LG https://github.com/simelo/repo-info-tools/raw/master/drib.sh -o drib.sh && chmod +x drib.sh
```

This very is handy for automation tasks, if you need it be completely silent, just run it like this.

```sh
$ curl -sLG https://github.com/simelo/repo-info-tools/raw/master/drib.sh -o drib.sh && chmod +x drib.sh
```

### Proxy operation

It can work over HTTP/HTTPS proxies, just take a peek on the code to modify and uncomment two lines.

### Script feedback

If your images are big and your bandwidth is slow the local part will take a while, it will download the image locally if not already downloaded, keep an eye on console.

If this is your case: take a trip to the nearest window to check if the outer world is there. ;-)
