# Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#
# Dockerfile for google/dart-test-runner

FROM google/dart

# Enable contrib and non-free packages.

RUN echo "deb http://gce_debian_mirror.storage.googleapis.com wheezy contrib non-free" >> /etc/apt/sources.list \
  && echo "deb http://gce_debian_mirror.storage.googleapis.com wheezy-updates contrib non-free" >> /etc/apt/sources.list \
  && echo "deb http://security.debian.org/ wheezy/updates contrib non-free" >> /etc/apt/sources.list
RUN apt-get update

# Install Chromium, required fonts and needed tools.

RUN echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula \
    select true | debconf-set-selections
RUN apt-get install --no-install-recommends -y -q chromium-browser \
    tar wget unzip xvfb xauth \
    ttf-kochi-gothic ttf-kochi-mincho ttf-mscorefonts-installer \
    ttf-indic-fonts ttf-dejavu-core fonts-thai-tlwg

# Install libc6-dev from testing cource.

RUN echo "deb http://ftp.debian.org/debian/ testing main contrib non-free" >> /etc/apt/sources.list
RUN apt-get update
RUN apt-get install --no-install-recommends -y -q libc6-dev

# Trick to have ttf-indic-fonts-core since ttf-indic-fonts is transitional.

WORKDIR /usr/share/fonts/truetype/ttf-indic-fonts-core
RUN ln -s ../lohit-punjabi/Lohit-Punjabi.ttf lohit_hi.ttf \
  && ln -s ../lohit-tamil/Lohit-Tamil.ttf lohit_ta.ttf \
  && ln -s ../fonts-beng-extra/MuktiNarrow.ttf \
  && ln -s ../lohit-punjabi/Lohit-Punjabi.ttf lohit_pa.ttf

# Install Dartium Content Shell.

WORKDIR /usr/local/content_shell
RUN wget https://storage.googleapis.com/dart-archive/channels/stable/release/latest/dartium/content_shell-linux-x64-release.zip
RUN unzip content_shell-linux-x64-release.zip \
  && rm content_shell-linux-x64-release.zip \
  && mv $(ls) latest
ENV PATH /usr/local/content_shell/latest:$PATH

# Install the Dart test runner.

ENV PATH $PATH:/root/.pub-cache/bin
RUN pub global activate test_runner

# Run Test Runner and display results.

ADD test.sh /usr/local/bin/test.sh
RUN chmod +x /usr/local/bin/test.sh

ENTRYPOINT ["/usr/local/bin/test.sh"]
