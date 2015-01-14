# Installation instructions for Content Shell

Content Shell is a stripped down version of Dartium/Chromium and it has the
ability to run headlessly. This is not the same thing as Dartium and if you
haven't already you likely need to install it.

To install Content Shell download the [correct archive for your environment]
(http://gsdview.appspot.com/dart-archive/channels/dev/release/latest/dartium/)
and follow the instructions for your environment:

## Linux

 - Unzip the archive into a folder
 - Add the folder to your `PATH`
 - Install the dependencies depending on your Linux distribution below.

### Ubuntu Trusty:

 - Enable multiverse packages:
 
```
echo "deb http://gce_debian_mirror.storage.googleapis.com wheezy contrib non-free" >> /etc/apt/sources.list
echo "deb http://gce_debian_mirror.storage.googleapis.com wheezy-updates contrib non-free" >> /etc/apt/sources.list
apt-get update
```

 - Install these dependencies:
 
```
apt-get install chromium-browser ttf-kochi-gothic ttf-kochi-mincho ttf-mscorefonts-installer \
  ttf-indic-fonts ttf-dejavu-core ttf-indic-fonts-core fonts-thai-tlwg
```

 - Trick to get libudev0:

```
ln -sf /lib/x86_64-linux-gnu/libudev.so.1 /lib/x86_64-linux-gnu/libudev.so.0
```

### Ubuntu Precise:

 - Enable multiverse packages:
 
```
echo "deb http://gce_debian_mirror.storage.googleapis.com precise contrib non-free" >> /etc/apt/sources.list
echo "deb http://gce_debian_mirror.storage.googleapis.com precise-updates contrib non-free" >> /etc/apt/sources.list
apt-get update
```

 - Install these dependencies:
 
```
apt-get install chromium-browser libudev0 ttf-kochi-gothic ttf-kochi-mincho \
  ttf-mscorefonts-installer ttf-indic-fonts ttf-dejavu-core ttf-indic-fonts-core fonts-thai-tlwg
```

### Debian Wheezy:

 - Enable contrib and non-free packages:
 
```
echo "deb http://archive.ubuntu.com/ubuntu/ trusty multiverse" >> /etc/apt/sources.list
echo "deb http://archive.ubuntu.com/ubuntu/ trusty-updates multiverse" >> /etc/apt/sources.list
apt-get update
```

 - Install these dependencies:
 
```
apt-get install chromium-browser ttf-kochi-gothic ttf-kochi-mincho ttf-mscorefonts-installer \
  ttf-indic-fonts ttf-dejavu-core fonts-thai-tlwg
```

 - Trick to fake ttf-indic-fonts-core since ttf-indic-fonts is transitional:
 
```
cd /usr/share/fonts/truetype
sudo mkdir ttf-indic-fonts-core
cd ttf-indic-fonts-core
sudo ln -s ../lohit-punjabi/Lohit-Punjabi.ttf lohit_hi.ttf
sudo ln -s ../lohit-tamil/Lohit-Tamil.ttf lohit_ta.ttf
sudo ln -s ../fonts-beng-extra/MuktiNarrow.ttf
sudo ln -s ../lohit-punjabi/Lohit-Punjabi.ttf lohit_pa.ttf
```

 - Install libc6-dev from testing source:
 
```
echo "deb http://ftp.debian.org/debian/ testing main contrib non-free" >> /etc/apt/sources.list
apt-get update
apt-get install libc6-dev
```

## Windows

 - Unzip the archive into a folder
 - Add the folder to your `PATH`

## Mac OS X

 - Unzip the archive and move the Content Shell.app file to your Application
   folder
 - Create a `content_shell` bash script in your `/usr/local/bin` folder (or
   another folder that's in your `PATH`) with the following content:
```
#!/bin/bash
"/Applications/Content Shell.app/Contents/MacOS/Content Shell" "$@"
```
### Homebrew

Alternatively you can simply install Content Shell using Homebrew:

    brew tap dart-lang/dart
    brew install dartium

Installing Dartium via Homebrew will also install Content Shell and create the
appropriate `content_shell` script.
