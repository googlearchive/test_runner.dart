# Dart Test Runner

The Dart Test Runner (DTR) is a command line Test Runner for Dart test files.
DTR will automatically detect and run all the tests in your Dart project in the
correct environment (VM or Browser).

## Installation and usage

DTR is available for download on the
[Pub Package Manager](https://pub.dartlang.org/packages/test_runner)

To install DTR use this command:

    pub global activate test_runner

To run DTR use this command from within the root of your Dart project:

    pub global run test_runner

Alternatively you can add the pub cache `bin` directory to your PATH:
`~/.pub-cache/bin`. Then you will be able to simply use:

    run_tests -c

For a list of options and to learn more use:

    run_tests --help

### Result

Here is an example of output from the Dart test runner:

    bash> run_tests

    Checking Dart binaries...
    Dart binaries OK.

    Looking for Dart project in "./"...
    Found project "test-runner".

    Looking for test suites...
    Found 5 test suites:
     - 3 Standalone VM
     - 2 Dartium

    Running all tests...
    Test suite passed: /vm_ok_test.dart
    Test suite passed: /subdir/vm_in_subdir_ok_test.dart
    Test suite failed: /vm_fail_test.dart
    Detailed results of test suite vm_fail_test.dart:
    ┌────────────────────────────────────────────────
    │ FAIL: QuickSort
    │   Expected: equals [1, 2, 3, 4, 5] ordered
    │     Actual: [3, 5, 2, 4, 1]
    │      Which: was <3> instead of <1> at location [0]
    │   ...
    │ FAIL: Partition
    │   Expected: <1>
    │     Actual: <0>
    │   ...
    │ 0 PASSED, 2 FAILED, 0 ERRORS
    Test suite passed: /browser_ok_test.dart
    Test suite passed: /browser_ok_with_html_test.dart

    Summary: 1 TEST SUITE(S) FAILED. 4 TEST SUITE(S) PASSED.

TIP: use the `-c` option to get a nice colored output

The exit code will be:

 - If all tests passed: `0`
 - If at least one test has failed: `1`
 - Incorrect command line argument (e.g. missing `pub` or `dart2js`, incorrect
   project path...): `2`
 - If no test files were found in the project: `3`

## Test files detection and conventions

Your tests have to follow certain conventions to be reliably detected by DTR.
Please make sure that:

 - Your tests files are suffixed with `_test.dart`
 - Each test file contains a `main()` that runs all your unit tests.

Depending on the environment into which your test runs there are additional
requirements listed below.

Each test file is considered a "test suite". If a test suites does not complete
in 240 seconds it is aborted.

### Standalone VM tests

Standalone VM tests are tests that can be run from the command line using
'dart'. The executable of the test needs to return an exit code of 0 if all
tests were successful and 1 or more if there was an error.

NOTE: Typically if you wrote your Standalone VM tests using the
[unittest package](https://pub.dartlang.org/packages/unittest) you should be all
set.

### Browser tests

Browser tests are tests that need to be ran in a browser environment such as
dartium.

Browser tests will be executed in a headless version of Chromium for Dart called
Content Shell. Content Shell is not the same thing as Dartium. If you don't have
Content Shell installed read the [specific section](#content-shell) about it.

If all tests have passed your test needs to print `PASS\n` ("PASS" followed by a
line break).

You can provide an HTML file for a Browser Test. The HTML file needs to
have the same base name (for `my_test.dart` use `my_test.html`).

You don't have to write an HTML file associated to your browser tests. The Dart
test runner will automatically use a default HTML file and run your Browser
tests in it if you didn't provide a custom one.

DTR will automatically detect if a test file needs to be ran inside a Browser if
there is no associated HTML file.

NOTE: Typically if you wrote browser tests using the
[unittest package](https://pub.dartlang.org/packages/unittest) you should be all
set as the Dart test runner will automatically and transparently set an
appropriate test `Configuration` and will import
`packages/unittest/test_controller.js` into the HTML page.

## Tools and environment

DTR runs on Linux, Mac OS X and Windows. DTR also needs the following tools
installed:

 - Content Shell: A headless version of Dartium. Needed to run browser tests.
   Not the same thing as Dartium. Make sure you read the
   [specific section](#content-shell) about it
 - Dart SDK: Especially the `pub` command which will be used to run and serve
   tests and `dart2js` which is used to detect browser tests.

Ideally make sure that these tools are available in your PATH as `pub`,
`dart2js` and `content_shell` (with a `.bat` or `.exe` extension in Windows).
You can also specify the path to these tools executables with
`--content-shell-bin`, `--pub-bin` and `--dart2js-bin`.

### Content Shell

Content Shell is a stripped down version of Dartium/Chromium and it has the
ability to run headlessly. This is not the same thing as Dartium and if you
haven't already you likely need to install it.

To install Content Shell download the [correct archive for your environment]
(http://gsdview.appspot.com/dart-archive/channels/dev/release/latest/dartium/)
and follow the instructions for your environment:

#### Linux

Linux instructions coming soon.

#### Windows

 - Unzip the archive into a folder
 - Add the folder to your `PATH`

#### Mac OS X

 - Unzip the archive and move the Content Shell.app file to your Application
   folder
 - Create a `content_shell` bash script in your `/usr/local/bin` folder (or
   another folder that's in your `PATH`) with the following content:
```
#!/bin/bash
"/Applications/Content Shell.app/Contents/MacOS/Content Shell" "$@"
```
Alternatively you can simply install Content Shell using Homebrew:

    brew tap dart-lang/dart
    brew install dartium

Installing Dartium via Homebrew will also install Content Shell and create the
appropriate `content_shell` script.

## Options and examples

### Usage

Generic usage of DTR:

    run_tests [options] [<project-or-tests>...]

Where `<project-or-tests>` is the path to the project root/test folder or a list
of path to individual test files to run. If omitted all tests of the current
project will be discovered and ran.

### Options

`--content-shell-bin`: Path to the Content Shell executable. If omitted
"content_shell" from env is used.

`--pub-bin`: Path to the Pub executable. If omitted "pub" from env is used.

`--dart2js-bin`: Path to the dart2js executable. If omitted "dart2js" from env
                 is used.

`--skip-browser-tests`: Skips all browser tests. Useful when browser binaries
                        like content_shell are not available.

`--max-processes`: Maximum number of processes that will run in parallel.
                   Defaults to "auto" which depends on the number of processors
                   available.

`-c` or `--color`: Prints the output in color in a shell.

`-v` or `--verbose`: Prints all tests results instead of just the summary.

`-h` or `--help`: Print usage information.

### Examples

Runs all unit tests of the project in the current directory with a colored
output:

    run_tests -c

Runs the specified two unit test files:

    run_tests test/my_first_test.dart test/my_second_test.dart

Runs all unit tests of the Dart project located at `~/my_project/`:

    run_tests ~/my_project/

Runs all tests of the project located at `~/my_project/` and use
`~/dartium/content_hell` as the Dartium executable.

    run_tests --content-shell-bin ~/dartium/content_shell ~/my_project/

## Test using Docker

The test environment can sometimes be tricky to setup (for instance Content
Shell in Linux). As an alternative we are providing a Docker image that can
be used to run your tests. There are also options to automatically run tests of
Pub packages or GitHub repos.

For more details read [docker/README](docker/README.md).

## License

BSD 3-Clause License.
See [LICENSE](LICENSE) file.
