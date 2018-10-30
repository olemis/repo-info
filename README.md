# Repo-info builder, pure bash for simplicity.

A simple as possible scripts to automate the generation of Docker metadata directory known as "repo-info"

## How to use it.

Are you using GNU/Linux right? (this is linux only)

Just clone it else where in your HDD, set the exec bit for all the .sh ones, copy all the .sh files to your image description folder (usualy where the Dockerfile resides) and run the getit.sh wiht the following parameters:

* local image name and optionally a tag (will default to :latest)
* remote image name
* registry URL for this image

## Example run

```
pavel@laptop ~$ git clone [clone-URL]
[...]
pavel@laptop ~$ cd repo-info
pavel@laptop ~$ chmod +x *.sh
pavel@laptop ~$ cp *.sh /path/to/your/destination/folder
pavel@laptop ~$ cd /path/to/your/destination/folder
pavel@laptop /path/to/your/destination/folder$ getit.sh busybox library/busybox https://hub.docker.com/library/busybox/
Ready to process the repo-info for 'busybox <> library/busybox'
Ready to process (remote) 'busybox:latest'
Retrieving image digest.
                IMAGE:  library/busybox
                TAG:    latest
                TOKEN: [...token...]

Ready to process (local) 'busybox:latest'
Done.
```

Now you can check your FS to see the created files.

## Gotchas ? 

* What if your repo is a private registry in docker hub?
* What if your registry is not registry.docker.io?

In this cases you will need to auth yourself to it to get it working and or change the registry path and auth path, see the [get-remote.sh](./get-remote.sh) file and uncommment/set the variables to suit your needs.

## Author

My name is Pavel Milanes, I'm starting on docker and cloud technologies with this scripts. Be gently with me.
  