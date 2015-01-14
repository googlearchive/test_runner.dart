# google/dart-test-runner

[`google/dart-test-runner`][2] is a [docker](https://docker.io) image that
makes it easy to run a [Dart](https://dartlang.org) applications tests.

It can automatically download a Dart application and its dependencies and run
all tests of the project in an environment pre-configured with all tools to run
tests (Dartium ContentShell, Dart SDK, Dart Test Runner...).

It is based on the [`ubuntu`][1] base image.

## Usage

You can use this Docker image to automatically download and test a Pub package,
a GitHub repo or a local project.

### Pub packages

To automatically download and test a Pub package run:

    docker run -e PKG=<package_name> -e VERSION=<package_version> google/dart-test-runner

example: `docker run -e PKG=test_runner -e VERSION=0.2.11 google/dart-test-runner`

example: `docker run -e PKG=test_runner -e VERSION=0.2.11 google/dart-test-runner:1.9.0_dev`

### GitHub repos

To automatically download and test a GitHub repo run:

    docker run -e REPO=<repo_path> -e BRANCH=<branch_name> google/dart-test-runner

example: `docker run -e REPO=google/test_runner.dart -e BRANCH=master google/dart-test-runner`

example: `docker run -e REPO=google/test_runner.dart -e BRANCH=1d10a11f0404be12ec643396c5b3db9041bb9919 google/dart-test-runner`

example: `docker run -e REPO=google/test_runner.dart google/dart-test-runner # Defaults to master`

example: `docker run -e REPO=google/test_runner.dart google/dart-test-runner:1.9.0_dev`

### Local projects

To test a local project. You need to first create a `Dockerfile` at the root of
your project with this content:

    FROM google/dart-test-runner
    ADD pubspec.* /app/
    WORKDIR /app
    RUN pub get
    ADD . /app
    RUN pub get --offline

To run the tests use:

    docker build -t my_project/tests .
    docker run my_project/tests

You can also pass options to the Dart Test Runner. For instance you can get a
colored output by adding `-c`:

    docker run -e REPO=google/test_runner.dart google/dart-test-runner -c

[1]: https://registry.hub.docker.com/_/ubuntu/
[2]: https://registry.hub.docker.com/u/google/dart-test-runner/
