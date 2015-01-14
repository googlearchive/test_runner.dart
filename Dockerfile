# This is an example of a Docker image that runs tests locally.
# Just need to run:
#     docker build -t my_project/tests . &&  docker run my_project/tests

FROM google/dart-test-runner
ADD pubspec.* /app/
WORKDIR /app
RUN pub get
ADD . /app
RUN pub get --offline
