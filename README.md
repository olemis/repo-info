# Docker Repo-info builder, pure bash for simplicity.

A simple as possible scripts to automate the generation of Docker metadata directory known as "repo-info"

The drib name cames com the initials: "Docker Repo-info builder"

## How to use it.

Are you using GNU/Linux right? (this is linux only, sorry.)

You can follow this simple steps:
* Clone the repo it in your HDD/project etc.
* Copy the drib.sh (only his file) to the folder that has your Dockerfile where you want to creat the repo-info folder _(You can do the steps abobe by getting the raw file from github, see how below)_
* Give exec right to the file:

```
chmod +x drib.sh
```

* Now run it, lets assume that you want to create the metadata folder for the latest 'registry' image (official docker image, so you must prepend the 'library/' to the name) let's see:

```
pavel@laptop:~/$ ./drib.sh library/registry
Ready to process the repo-info for 'library/registry => library/registry'.
Getting remote info...
Done.
Getting local info...
Done.
All Done, thank you.
pavel@agatha-lt:~/$
```

Now you can check your folder to see the created files, will have a folder named "repo-info" with the data on it. 

Now you can remove the drib.sh file if you like or let it be for future updates.

## Troubles?

If you get in troubles with it or manages to crash it, use the Issues tab.

## Good to Know...

The syntax of the command line is:

```
./drib.sh <local_image[:local_tag]> [remote_image[:remote-tag]]
```

As you see the only needed parameter is the local image, the tags are assumes as 'latest' is not specified.

As you can see, you can run it with different local and remote image names and also tags.

## Author

My name is Pavel Milanes, I'm starting on docker and cloud technologies with this scripts. Be gently on me.
