# Docker Repo-info builder, pure bash for simplicity.

A simple as possible scripts to automate the generation of Docker metadata directory known as "repo-info"

The drib name cames com the initials: "Docker Repo-info builder"

## How to use it.

Are you using GNU/Linux right? (this is linux only, sorry.)

You can follow this simple steps:
* Clone the repo it in your HDD/project etc.
* Copy the drib.sh (only his file) to the folder that has your Dockerfile where you want to creat the repo-info folder _(You can do the steps abobe by getting the raw file from github, see how below)_
* Give exec right to the file:

```sh
chmod +x drib.sh
```

* Now run it, lets assume that you want to create the metadata folder for the latest 'registry' image (official docker image, so you must prepend the 'library/' to the name) let's see:

```sh
$ ./drib.sh library/registry
Ready to process the repo-info for 'library/registry => library/registry'.
Getting remote info...
Got token from: https://auth.docker.io/token?service=registry.docker.io&scope=repository:library/registry:pull
Get remote digest: sha256:2e2f252f3c88679f1207d87d57c07af6819a1a17e22573bcef32804122d2f305
Got image config
Parsing remote data to ./repo-info/remote/latest.md
Done remote.
Getting local info...
Pulling the image from docker hub
Using default tag: latest
latest: Pulling from library/registry
d6a5679aa3cf: Pull complete 
ad0eac849f8f: Pull complete 
2261ba058a15: Pull complete 
f296fda86f10: Pull complete 
bcd4a541795b: Pull complete 
Digest: sha256:5a156ff125e5a12ac7fdec2b90b7e2ae5120fa249cf62248337b6d04abc574c8
Status: Downloaded newer image for registry:latest
Parsing local data to ./repo-info/local/latest.md
Done local.
All Done, thank you.
```

Now you can check your folder to see the created files, will have a folder named "repo-info" with the data on it. 

Now you can remove the drib.sh file if you like or let it be for future updates.

## Troubles?

If you get in troubles with it or manages to crash it, please [search it was already reported](https://github.com/simelo/repo-info-tools/issues) and , if not, then [file an issue](https://github.com/simelo/repo-info-tools/issues/new) .

## Good to Know...

The syntax of the command line is:

```sh
./drib.sh <local_image[:local_tag]> [remote_image[:remote-tag]]
```

As you see the only needed parameter is the local image, the tags are assumes as 'latest' is not specified.

As you can see, you can run it with different local and remote image names and also tags.

### Getting the file, fast way

You can fetch & setup the file in just one line with this command: (You need to move to the folder where you want to run it before)

```sh
curl -LG https://github.com/simelo/repo-info-tools/raw/master/drib.sh -o drib.sh && chmod +x drib.sh
```

This very is handy for automation tasks, if you need it be completely silent, just run it like this.

```sh
curl -sLG https://github.com/simelo/repo-info-tools/raw/master/drib.sh -o drib.sh && chmod +x drib.sh
```

### Proxy operation

It can work over HTTP/HTTPS proxies, just take a peek on the code to modify and uncomment two lines.

### Script feedback

If your images are big and your bandwidth is slow the local part will take a while, it will download the image locally if not already dowloaded.

If this is your case: take a trip to the nearest window to check if the outer world is there. ;-)

## Author

My name is Pavel Milanes, I'm starting on docker and cloud technologies with this scripts. Be gently on me.
