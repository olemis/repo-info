# Docker Repo-info builder, pure bash for simplicity.

A simple as possible scripts to automate the generation of Docker metadata directory known as "repo-info"

The drib name cames com the initials: "Docker repo-info builder"

## How to use it.

Are you using GNU/Linux right? (this is linux only, sorry.)

You can follow this simple steps:
* Clone the repo it in your HDD/project etc.
* Copy the drib.sh (only this file) to the folder that has your Dockerfile where you want to creat the repo-info folder _(You can do the steps abobe by getting the raw file from github, see how below)_
* Give exec right to the file:

```sh
$ chmod +x drib.sh
```

* Now run it, lets assume that you want to create the metadata folder for the latest 'registry' image (official docker image, so you must prepend the 'library/' to the name) let's see:

```sh
$ ./drib.sh library/registry
[TODO Update with a fresh output]
```

Now you can check your folder to see the created files, will have a folder named "repo-info" with the data on it. 

Now you can remove the drib.sh file if you like or let it be for future updates.

## Search & process all tags for a given image.

Imagine you are the maintainer of a group of docker images for a project in a public repository (Docker Hub, but can be others) with just different tags.... 

How wonderfull will be if you can make the repo-info for all tags in the repository for a given image name?

Wonder no more, run it with two special arguments '-a' and your image name:

```sh
$ ./drib.sh -a library/registry
[TODO, real listing of work done]
```

## What if you maintain a group of images for a project, each one with a few different tags?

Yes, it will be wonderfull, don't you think? I'm working on that direction, just **Stay tuned!**

## Troubles?

If you get in troubles with it or manages to crash it, please [search your problem to see if it was already reported](https://github.com/simelo/repo-info-tools/issues) and, if not, then [file an issue](https://github.com/simelo/repo-info-tools/issues/new) .

## Good to Know...

### The basic syntax of the command line is:

```sh
$ ./drib.sh <local_image[:local_tag]> [remote_image[:remote-tag]]
```

As you see the only needed parameter is the local image, the tags are assumes as 'latest' is not specified.

Also note that you can run it with different local and remote image names and also tags.

### The search and process all tags command line syntax is like this:

```sh
$ ./drib.sh -a <repository>
```

In this case all options are mandatory and 'repository' reffers to a docker hub registry entry like 'library/registry' or 'skycoin/skycoin'

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

If your images are big and your bandwidth is slow the local part will take a while, it will download the image locally if not already dowloaded, keep an eye on console.

If this is your case: take a trip to the nearest window to check if the outer world is there. ;-)

## Author

My name is Pavel Milanes, I'm starting on docker and cloud technologies with this scripts. Be gently on me.
