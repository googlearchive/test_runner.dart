#!/bin/bash
# Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
# This script is intended to use inside a Docker image. It will:
#  - Download a Dart app and deploys it or use an already loaded dart app.
#  - Runs all test of the Dart app.
#
# Before calling this script you must either:
#  - Set the PKG and VERSION environment variable (for Pub packages).
#  - Set the REPO environment variable (for GitHub repos).
#  - Load a local Dart project in the /app directory.
#
# See Dockerfile comment and README for end-to-end usage.

mkdir /app >/dev/null 2>&1
cd /app

# Download and deploy app from Pub.

if [ ! -z "$PKG" ]; then
    echo "Downloading Dart package from Pub..."
    wget https://storage.googleapis.com/pub.dartlang.org/packages/$PKG-$VERSION.tar.gz >/dev/null 2>&1
    if [ $? != 0 ]; then
      >&2 echo "The Pub package \"$PKG\" version \"$VERSION\" was not found. Make sure you set the PKG and VERSION environment variables correctly."
      exit 4
    fi
    tar -zxf $PKG-$VERSION.tar.gz
    pub get >/dev/null 2>&1
    echo "Dart package downloaded."

# Download and deploy app from GitHub.

elif [ ! -z "$REPO" ]; then
    if [ -z "$BRANCH" ]; then
        export BRANCH=master
    fi
    echo "Downloading Dart app from GitHub..."
    wget https://github.com/$REPO/archive/$BRANCH.zip >/dev/null 2>&1
    if [ $? != 0 ]; then
      >&2 echo "The branch \"$BRANCH\" of the GitHub repo \"$REPO\" was not found. Make sure you set the REPO and BRANCH environment variables correctly."
      exit 4
    fi
    unzip $BRANCH.zip >/dev/null 2>&1
    rm $BRANCH.zip
    mv $(ls) branch
    cd branch
    pub get >/dev/null 2>&1
    echo "Dart app downloaded."

# Use a loaded local project.

elif [ "$(ls)" != "" ]; then
    echo "Using local Dart project..."
    pub get >/dev/null 2>&1

# In case of misuse.

else
    >&2 echo "Before calling this script you must either:"
    >&2 echo " - Set the PKG and VERSION environment variables (for Pub packages)."
    >&2 echo " - Set the REPO environment variable (for GitHub repos)."
    >&2 echo " - Load a local Dart project in the Docker image /app directory."
    exit 5;
fi

# Run Test Runner and display results.
xvfb-run -s '-screen 0 1024x768x24' run_tests $@
