# Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
# Dockerfile for google/dart-test-runner

FROM ubuntu:trusty
ENV DART_VERSION 1.8.3
ENV DEBIAN_FRONTEND noninteractive

# Enable Multiverse packages.

RUN echo "deb http://archive.ubuntu.com/ubuntu/ trusty multiverse" >> /etc/apt/sources.list \
  && echo "deb http://archive.ubuntu.com/ubuntu/ trusty-updates multiverse" >> /etc/apt/sources.list
RUN apt-get -q update

# Install Chromium, required fonts and needed tools.

RUN echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula \
    select true | debconf-set-selections
RUN apt-get install --no-install-recommends -y -q chromium-browser \
    tar curl git ca-certificates apt-transport-https wget unzip xvfb \
    ttf-kochi-gothic ttf-kochi-mincho ttf-mscorefonts-installer \
    ttf-indic-fonts ttf-dejavu-core ttf-indic-fonts-core fonts-thai-tlwg

# Trick to have libudev0.

RUN ln -sf /lib/x86_64-linux-gnu/libudev.so.1 /lib/x86_64-linux-gnu/libudev.so.0

# Install Dartium Content Shell.

RUN mkdir /usr/local/content_shell
WORKDIR /usr/local/content_shell
RUN wget https://storage.googleapis.com/dart-archive/channels/stable/release/latest/dartium/content_shell-linux-x64-release.zip
RUN unzip content_shell-linux-x64-release.zip
RUN rm content_shell-linux-x64-release.zip
RUN mv $(ls) latest
ENV PATH /usr/local/content_shell/latest:$PATH

# Install the Dart SDK.

RUN curl https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
  curl https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list && \
  apt-get update && \
  apt-get install dart=$DART_VERSION-1

ENV DART_SDK /usr/lib/dart
ENV PATH $DART_SDK/bin:$PATH

# Install the Dart test runner.

ENV PATH $PATH:/root/.pub-cache/bin
RUN pub global activate test_runner

# Run Test Runner and display results.

ADD test.sh /usr/local/bin/test.sh
RUN chmod +x /usr/local/bin/test.sh

ENTRYPOINT ["/usr/local/bin/test.sh"]
