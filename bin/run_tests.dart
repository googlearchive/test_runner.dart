// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_runner;

import 'dart:io';
import 'package:ansicolor/ansicolor.dart';
import 'package:unscripted/unscripted.dart';

import 'package:test_runner/dart_project.dart';
import 'package:test_runner/dart_binaries.dart';
import 'package:test_runner/test_configuration.dart';
import 'package:test_runner/test_runner.dart';

/// Entry point which simply calls [runTests] with the command line arguments.
main(arguments) => declare(runTests).execute(arguments);

/// Red colored modifiers for writing to terminal in color mode.
var redPen = (String s) => s;

/// Green colored modifiers for writing to terminal in color mode.
var greenPen = (String s) => s;

/// Un-colored underlined modifiers for writing to terminal.
var underlinePen = (String s) => s;

// All metadata annotations are optional.
@Command(help: 'Runs Dart unit tests')
@ArgExample('', help: 'Runs all unit tests of the project in the current directory')
@ArgExample('tests/test1.dart tests/test2.dart',
    help: 'Runs the specified unit test files of the project in the current directory')
@ArgExample('--project-path ~/my_project/',
    help: 'Runs all unit tests of the project located at ~/my_project/')
@ArgExample('--content-shell-bin ~/dartium/content_hell -p ~/my_project/',
    help: 'Runs all tests of the project located at ~/my_project/. Sets ~/dartium/content_shell as the Content Shell executable.')
runTests(
    @Rest(help: 'Path to the project root/test folder or list of path to individual test files to run. If omitted all tests of the current project will be discovered and ran.')
    List<String> projectOrTests,
    {@Option(help: 'Path to the Content Shell executable. If omitted "content_shell" from env is used.')
    String contentShellBin: "content_shell",
    @Option(help: 'Path to the Pub executable. If omitted "pub" from env is used.')
    String pubBin: "pub",
    @Option(help: 'Path to the dart2js executable. If omitted "dart2js" from env is used.')
    String dart2js: "dart2js",
    @Flag(abbr: 'c', help: 'Prints the output in color in a shell.')
    bool color : false,
    @Flag(abbr: 'v', help: 'Prints all tests results instead of just the summary.')
    bool verbose : false}) {

  // Make output pretty and colored if requested.

  if (color) {
    redPen = new AnsiPen()..red(bold: true);
    greenPen = new AnsiPen()..green(bold: true);
    underlinePen = (String s) => "\x1B[4m$s\x1B[0m";
  }

  // Find out if user has passed a list of test files or a Dart project.

  String projectPath;
  List<String> tests = new List();
  if (projectOrTests == null || projectOrTests.length == 0) {
    projectPath = "./";
  } else {
    bool allDartFiles = projectOrTests.every(
        (String path) => path.endsWith(".dart"));

    bool oneDartFiles = projectOrTests.any(
            (String path) => path.endsWith(".dart"));

    if (oneDartFiles && !allDartFiles) {
      stderr.writeln(redPen("\nYou can only specify one Dart project directory "
          "or a list of test files.\n"));
      exit(2);
    } else if (!allDartFiles && projectOrTests.length == 1) {
      projectPath = projectOrTests[0];
    } else {
      tests = projectOrTests;
      projectPath = projectOrTests[0].substring(0,
          projectOrTests[0].lastIndexOf("test/") + 5);
    }
  }

  // Step 1: Check if all binaries path have been set correctly.

  DartBinaries dartBinaries =
      new DartBinaries(contentShellBin, pubBin, dart2js);
  print("\nChecking Dart binaries...");
  try {
    dartBinaries.checkBinaries();
  } catch (e) {
    stderr.writeln(redPen("$e\n"));
    exit(2);
  }
  print(greenPen("Dart binaries OK."));

  // Step 2: Check if a Dart project can be found in [projectPathUri].

  DartProject dartProject = new DartProject(projectPath, dartBinaries);
  print("\nLooking for Dart project in \"$projectPath\"...");
  try {
    dartProject.checkProject();
  } catch (e) {
    stderr.writeln(redPen("$e\n"));
    exit(2);
  }
  print(greenPen("Found project \"${dartProject.pubSpecYaml["name"]}\"."));

  // Step 3: Detect all unit tests and extract their configuration.

  print("\nLooking for test files...");
  try {
    dartProject.findTests(tests);
  } catch (e) {
    stderr.writeln(redPen("$e\n"));
    exit(2);
  }
  dartProject.tests.toList().then((List<TestConfiguration> tests) {
    List<TestConfiguration> browserTests = tests.where(
        (TestConfiguration t) => t.testType is BrowserTest).toList();
    print(greenPen("Found ${tests.length} test files:"));
    print(greenPen(" - ${tests.length - browserTests.length} Standalone VM"));
    print(greenPen(" - ${browserTests.length} Dartium"));


    // Step 4: Run all tests and catch their output so that we can print it on
    // the command line.

    print("\nRunning all tests...");
    TestRunnerDispatcher testRunners =
        new TestRunnerDispatcher(dartBinaries, dartProject);
    testRunners.runTests(tests)

      ..listen((TestExecutionResult result) {
        // As soon as each test is finished we display the results.
        if (verbose) {
          print(underlinePen("\nResult of test: ${result.test.testFileName}"));
          print(result.testOutput.trim());
          if (result.testErrorOutput.trim() != "")
            print(redPen(result.testErrorOutput.trim()));
        }

        if (result.success) {
          print(greenPen("Test passed: ${result.test.testFileName}"));
        } else {
          print(redPen("Test failed: ${result.test.testFileName}"));
        }
      })

      // Step 5: Display summary of tests results and cleanup generated files.

      ..toList().then((List<TestExecutionResult> results) {

        // Cleanup generated files.
        TestRunnerCodeGenerator.deleteGeneratedTestFilesDirectory(dartProject);

        // When all te tests are finished we display a summary and exit.
        List<TestExecutionResult> failedTestResults =
            results.where((TestExecutionResult t) => !t.success).toList();
        if (failedTestResults.length == 0) {
          print(greenPen("\nSummary: ALL ${tests.length} TEST FILE(S) "
              "PASSED.\n"));
          exit(0);
        } else if (failedTestResults.length == tests.length) {
          print(redPen("\nSummary: ALL ${failedTestResults.length} TEST FILE(S)"
              " FAILED.\n"));
          exit(1);
        } else {
          print("\nSummary: "
              + redPen("${failedTestResults.length} TEST FILE(S) FAILED. ")
              + greenPen("${tests.length - failedTestResults.length} TEST "
                  "FILE(S) PASSED.\n"));
          exit(1);
        }
      });
  });


}
