// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_runner;

import 'dart:async';
import 'dart:io';

import 'package:ansicolor/ansicolor.dart';
import 'package:unscripted/unscripted.dart';

import 'package:test_runner/test_runner.dart';
import 'package:test_runner/src/util.dart';
import 'package:test_runner/src/browser_test_runner.dart';

/// Entry point which simply calls [runTests] with the command line arguments.
void main(List<String> arguments) => declare(runTests).execute(arguments);

typedef String _Pen(String input);

/// Red colored modifiers for writing to terminal in color mode.
_Pen _redPen = (String s) => s;

/// Green colored modifiers for writing to terminal in color mode.
_Pen _greenPen = (String s) => s;

/// Orange colored modifiers for writing to terminal in color mode.
_Pen _orangePen = (String s) => s;

/// Un-colored underlined modifiers for writing to terminal.
_Pen _underlinePen = (String s) => s;

// All metadata annotations are optional.
@Command(help: 'Runs Dart unit tests')
@ArgExample('', help: 'Runs all unit tests of the project in the current '
                      'directory')
@ArgExample('tests/test1.dart tests/test2.dart',
    help: 'Runs the specified unit test files of the project in the current '
          'directory')
@ArgExample('~/my_project/',
    help: 'Runs all tests of the project located at ~/my_project/')
@ArgExample('--content-shell-bin ~/dartium/content_shell ~/my_project/',
    help: 'Runs all tests of the project located at ~/my_project/. Sets '
          '~/dartium/content_shell as the Content Shell executable.')
void runTests(
    @Rest(help: 'Path to the project root/test folder or list of path to '
                'individual test files to run. If omitted all tests of the '
                'current project will be discovered and ran.')
    List<String> projectOrTests,
    {@Option(help: 'Path to the Content Shell executable. If omitted '
                   '"${DartBinaries.CONTEST_SHELL_BIN_NAME}" from env is used.')
    String contentShellBin: DartBinaries.CONTEST_SHELL_BIN_NAME,
    @Option(help: 'Path to the Pub executable. If omitted '
                  '"${DartBinaries.PUB_BIN_NAME}" from env is used.')
    String pubBin: DartBinaries.PUB_BIN_NAME,
    @Option(help: 'Path to the dart2js executable. If omitted '
                  '${DartBinaries.DART2JS_BIN_NAME} from env is used.')
    String dart2jsBin: DartBinaries.DART2JS_BIN_NAME,
    @Option(help: 'Path to the dart executable. If omitted '
                  '${DartBinaries.DART_BIN_NAME} from env is used.')
    String dartBin: DartBinaries.DART_BIN_NAME,
    @Option(help: 'Maximum number of processes that will run in parallel. '
                  '"auto" will use the number of processors available on the '
                  'machine. Otherwise an integer is expected.')
    String maxProcesses: "auto",
    @Option(help: 'Provide a custom default html file for browser tests.')
    String defaultHtmlTemplate: "",
    @Option(help: 'Provide a custom VM Dart template file for executing VM tests.')
    String vmDartTemplate: "",
    @Flag(abbr: 'c', help: 'Prints the output in color in a shell.')
    bool color : false,
    @Flag(abbr: 'v', help: 'Prints all tests results instead of just the '
                           'summary.')
    bool verbose : false,
    @Flag(help: 'Skips all browser tests. Useful when browser binaries like '
                'content_shell are not available.')
    bool skipBrowserTests : false,
    @Flag(help: 'Disables the special ANSI character used in the console '
                'output for things like dynamic line updating and color. '
                'This is activated automatically on Windows.')
    bool disableAnsi : false,
    @Flag(help: 'This is for debugging purposes. The temporary files created '
                'by the test runner won\'t be deleted when the test runner '
                'finishes. Temporary files are created under '
                'test/$GENERATED_TEST_FILES_DIR_NAME')
    bool keepTemporaryFiles : false}) {


  // Disable special ANSI characters automatically on Windows.

  if(Platform.isWindows) {
    disableAnsi = true;
  }

  // Make output pretty and colored if requested.

  if (color && !disableAnsi) {
    _redPen = new AnsiPen()..red(bold: true);
    _greenPen = new AnsiPen()..green(bold: true);
    _orangePen = new AnsiPen()..rgb(r: 1,g: 0.45,b: 0);
    _underlinePen = (String s) => "\x1B[4m$s\x1B[0m";
  }

  // Find out how many max processes to run in parallel.

  int maxParallelProcesses;
  if (maxProcesses == "auto") {
    maxParallelProcesses = Platform.numberOfProcessors;
  } else {
    maxParallelProcesses = int.parse(maxProcesses, onError: (String source) {
      print(_redPen("You specified '$source' as the maximum number of "
          "concurrent processes. THis is invalid. You must specify a number "
          "or 'auto' for the '--max-processes' option."));
      return 4;
    });
  }

  // Find out if user has passed a list of test files or a Dart project folder.

  String projectPath;
  List<String> testPaths = new List();
  if (projectOrTests == null || projectOrTests.length == 0) {
    projectPath = "./";
  } else {
    bool allDartFiles = projectOrTests.every(
        (String path) => path.endsWith(".dart"));

    bool oneDartFiles = projectOrTests.any(
            (String path) => path.endsWith(".dart"));

    if (oneDartFiles && !allDartFiles) {
      stderr.writeln(_redPen("\nYou can only specify one Dart project "
          "directory or a list of test files.\n"));
      exit(2);
    } else if (!allDartFiles && projectOrTests.length == 1) {
      projectPath = projectOrTests[0];
    } else {
      testPaths = projectOrTests;
      projectPath = projectOrTests[0].substring(0,
          projectOrTests[0].lastIndexOf("test/") + 5);
    }
  }

  // Step 1: Check if the SDK binaries path have been set correctly.

  DartBinaries dartBinaries =
      new DartBinaries(contentShellBin, pubBin, dart2jsBin, dartBin);
  print("\nChecking Dart SDK binaries...");
  try {
    dartBinaries.checkDartSdkBinaries();
  } catch (e) {
    stderr.writeln(_redPen("$e\n"));
    exit(2);
  }
  print(_greenPen("Dart SDK binaries OK."));

  // Step 2: Check if a Dart project can be found in [projectPathUri].

  DartProject dartProject = new DartProject(projectPath, dartBinaries,
                                            maxProcesses: maxParallelProcesses,
                                            customDefaultHtmlPath: defaultHtmlTemplate,
                                            customVmDartTemplatePath: vmDartTemplate);
  print("\nLooking for Dart project in \"$projectPath\"...");
  try {
    dartProject.checkProject();
  } catch (e) {
    stderr.writeln(_redPen("$e\n"));
    exit(2);
  }
  print(_greenPen("Found project \"${dartProject.pubSpecYaml["name"]}\"."));

  // Step 2 bis: Run `pub get` if it has not been ran on the project.

  if (!dartProject.packagesFolderExists) {
    stdout.writeln(
        _orangePen("The packages folder does not exists. Running pub get."));
    ProcessResult result = Process.runSync(dartBinaries.pubBin, ["get"]);
    if (result.exitCode != 0) {
      stderr.writeln(_redPen("Pub get has failed: ${result.stderr}\n"));
      exit(2);
    }
  }

  // Step 3: Detect all unit tests and extract their configuration.

  stdout.write("\nLooking for test suites...");

  Stream<TestConfiguration> testStream;
  try {
    testStream = dartProject.findTests(testPaths);
  } catch (e) {
    stdout.write("\n");
    stderr.writeln(_redPen("$e\n"));
    exit(2);
  }

  _configToListAndLog(testStream, skipBrowserTests, disableAnsi).then(
      (List<TestConfiguration> tests) {

        // Error if no tests were found.
        if (tests == null || tests.length == 0) {
          if (!disableAnsi) {
            print('\x1b[2A');
          }
          stderr.writeln(_redPen("No tests files were found."
              "                                   \n"));
          exit(3);
        }

        _displayTestCount(tests, true, skipBrowserTests, false, disableAnsi);

        // Step 3 bis: Check if browser binaries have been set correctly.

        // Count browser tests.
        List<TestConfiguration> browserTests = tests.where(
                (TestConfiguration t) => t.testType is BrowserTest).toList();

        // If there are browser tests and we need to run them. Check for browser
        // binaries.
        if (browserTests.length > 0 && !skipBrowserTests) {
          print("\nChecking browser binaries...");
          try {
            dartBinaries.checkBrowserBinaries();
          } catch (e) {
            stderr.writeln(_redPen("$e"));
            stderr.writeln(_redPen("You can choose to skip all browser tests "
                "by using the --skip-browser-tests option and this binary "
                "won't be needed.\n"));
            exit(2);
          }
          print(_greenPen("Browser binaries OK."));
        } else if (skipBrowserTests) {
          // If skipBrowserTests is true we remove all Browser tests.
          tests.removeWhere((config) => config.testType is BrowserTest);
        }

        // Step 4: Run all tests and catch their output so that we can print it
        // on the command line.

        print("\nRunning all tests...");

        // If there are Browser tests we make sure the HTTP Server is started
        // before the VM tests are ran.
        // This is done because there are some potential conflicts with the `pub
        // get` ran by VM tests.
        if(browserTests.length > 0) {
          new BrowserTestRunner(dartBinaries, dartProject).startHttpServer()
              .then((_) {
                _runTestsAndDisplayResults(dartBinaries, dartProject,
                    maxParallelProcesses, tests, verbose, keepTemporaryFiles);
              });
        } else {
          _runTestsAndDisplayResults(dartBinaries, dartProject,
              maxParallelProcesses, tests, verbose, keepTemporaryFiles);
        }
  });
}

/// Run all the tests and display their results.
void _runTestsAndDisplayResults(dartBinaries, dartProject, maxParallelProcesses,
                               tests, verbose, keepTemporaryFiles) {

  TestRunnerDispatcher testRunners =
  new TestRunnerDispatcher(dartBinaries, dartProject,
  maxProcesses: maxParallelProcesses);
  testRunners.runTests(tests)
    ..listen((TestExecutionResult result) {
      // As soon as each test is finished we display the results.
      if (verbose) print("");
      if (result.success) {
        print(_greenPen("Test suite passed: "
        + result.test.testFileName));
      } else {
        print(_redPen("Test suite failed: ${result.test.testFileName}"));
      }
      if (verbose || !result.success) {
        print("Detailed results of test suite "
              "${result.test.testFileName}:");
        print(_makeWindowsCompatible("┌───────────────────────────────"
                                     "${result.test.testFileName.replaceAll(
                                         new RegExp(r'.'), '─')}"));

        if (result.testOutput.trim() != ""
            || result.testErrorOutput.trim() != "") {
          print(result.testOutput.trim()
              .replaceAll("\r", "")
              .replaceAll(new RegExp(r"^"), _makeWindowsCompatible("│ "))
              .replaceAll("\n", _makeWindowsCompatible("\n│ ")));
          if (result.testErrorOutput.trim() != "")
            print(result.testErrorOutput.trim()
                .replaceAll("\r", "")
                .replaceAll(new RegExp(r"^"), _makeWindowsCompatible("│ "))
                .replaceAll("\n", _makeWindowsCompatible("\n│ ")));
        } else {
          print(_makeWindowsCompatible("│ There was no test output."));
        }
        print(_makeWindowsCompatible("└───────────────────────────────"
                                     "${result.test.testFileName.replaceAll(
                                         new RegExp(r'.'), '─')}"));
      }
    })

    // Step 5: Display summary of tests results and cleanup generated
    // files.

    ..toList().then((List<TestExecutionResult> results) {

      if (!keepTemporaryFiles) {
        // Cleanup generated files.
        TestRunnerCodeGenerator
            .deleteGeneratedTestFilesDirectory(dartProject);
      }

      // Eventually stop the `pub serve`.
      if (BrowserTestRunner.pubServer != null) {
        BrowserTestRunner.pubServer.then((Process process)
            => process.kill());
      }

      // When all te tests are finished we display a summary and exit.
      List<TestExecutionResult> failedTestResults =
      results.where((TestExecutionResult t) => !t.success).toList();
      if (failedTestResults.length == 0) {
        print(_greenPen("\nSummary: ALL ${results.length} TEST SUITE(S) "
              "PASSED.\n"));
        exit(0);
      } else if (failedTestResults.length == results.length) {
        print(_redPen("\nSummary: ALL ${failedTestResults.length} "
              "TEST SUITE(S) FAILED.\n"));
        exit(1);
      } else {
        print("\nSummary: " + _redPen("${failedTestResults.length} "
              "TEST SUITE(S) FAILED. ")
              + _greenPen("${results.length - failedTestResults.length} "
              "TEST SUITE(S) PASSED.\n"));
        exit(1);
      }
    });
}

Future<List<TestConfiguration>> _configToListAndLog(
    Stream<TestConfiguration> testStream, bool skipBrowserTests, disableAnsi) {

  List<TestConfiguration> partialListOfTests = new List();

  // Initialise the display of the test detection process
  _displayTestCount(partialListOfTests, false, skipBrowserTests, true,
      disableAnsi);

  return testStream.forEach((conf) {
    partialListOfTests.add(conf);
    _displayTestCount(partialListOfTests, true, skipBrowserTests, true,
        disableAnsi);
  }).then((_) => partialListOfTests);
}

/// Displays the information about [tests] found.
void _displayTestCount(List<TestConfiguration> tests, bool erasePreviousLines,
                      bool skipBrowserTests, bool partial, bool disableAnsi) {
  if (erasePreviousLines && !disableAnsi) {
    print('\x1b[3A');
  }

  // In the case of non ANSI output we just display a dot to show progress.
  if (partial && disableAnsi) {
    stdout.write(".");
  } else {
    // Find out how many tests are browser tests.
    List<TestConfiguration> browserTests = tests.where(
            (TestConfiguration t) => t.testType is BrowserTest).toList();

    print(_greenPen("\nFound ${tests.length} test suites "
    "(${tests.length - browserTests.length} "
    "Standalone VM, ${browserTests.length} Dartium)."
    + (partial ? ".." : "  ")));

    if (browserTests.length > 0 && skipBrowserTests) {
      if ((partial && !disableAnsi) || !partial) {
        print(_orangePen("Dartium tests will be skipped!"));
      }
      if (partial && !disableAnsi) {
        print('\x1b[2A');
      }
    }
  }
}

String _makeWindowsCompatible(String s) {
  if(Platform.isWindows) {
    return s.replaceAll("┌", ".")
            .replaceAll("─", "-")
            .replaceAll("│", "|")
            .replaceAll("└", ".");
  } else {
    return s;
  }
}
