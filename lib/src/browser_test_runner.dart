// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_runner.browser_test_runner;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'dart_binaries.dart';
import 'dart_project.dart';
import 'test_configuration.dart';
import 'test_execution_result.dart';
import 'test_runner.dart';
import 'browser_test_runner_code_generator.dart';
import 'util.dart';

/// Runs Dart tests that can be run in a web browser.
class BrowserTestRunner extends TestRunner {

  /// Port to be used by the [WebServer] serving the test files.
  static int webServerPort = 7478;

  /// Host to be used by the [WebServer] serving the test files.
  static const String _WEB_SERVER_HOST = "127.0.0.1";

  /// Points to the pub server [Process].
  static Future<Process> pubServer;

  /// Pointers to all Dart SDK binaries.
  final DartBinaries dartBinaries;

  /// Pointers to the Dart Project containing the tests.
  final DartProject dartProject;

  /// Constructor.
  BrowserTestRunner(this.dartBinaries, this.dartProject);

  @override
  Future<TestExecutionResult> runTest(TestConfiguration test) {
    Completer<TestExecutionResult> completer = new Completer();

    // Create the temporary generated test files.
    BrowserTestRunnerCodeGenerator codeGenerator =
        new BrowserTestRunnerCodeGenerator(dartProject);
    Future htmlFileFuture = codeGenerator.createTestHtmlFile(
        test.testFileName, (test.testType as BrowserTest).htmlFilePath);
    Future dartFileFuture = codeGenerator.createTestDartFile(test.testFileName);

    // Start the Web Server and run the test.
    Future httpServer = startHttpServer();

    // Runs the Web Test in Content Shell when the files have been created and
    // when all the test files have been generated.
    Future.wait([htmlFileFuture, dartFileFuture, httpServer]).then((_) {

      String testUrl = _buildBrowserTestUrl(test.testFileName);

      String testOutput = "";
      String testErrorOutput = "";
      var success = false;
      var complete = () {
        if (!completer.isCompleted) {
          TestExecutionResult result = new TestExecutionResult(test,
          success: success,
          testOutput: testOutput,
          testErrorOutput: testErrorOutput);
          completer.complete(result);
        }
      };

      Process.start(dartBinaries.contentShellBin,
                ["--args", "--dump-render-tree",
                 "--disable-gpu", testUrl], runInShell: false)
             .then((Process testProcess) {

        testProcess.stdout.transform(new Utf8Decoder())
            .transform(new LineSplitter())
            .listen((String line) {
              if (line == "#CRASHED") {
                throw new Exception("Error: Content shell crashed.");
              } else  if (line == "PASS"){
                testOutput = "$testOutput\n$line";
                success = true;
              } else if (line == "#EOF") {
                complete();
                testProcess.kill();
              } else if (line != "CONSOLE MESSAGE: Warning: The "
                                 "unittestConfiguration has already been set. "
                                 "New unittestConfiguration ignored."
                  && line != "Content-Type: text/plain"
                  && line != "#READY"
                  && line != "#EOF"
                  && line != "unittest-suite-wait-for-done") {
                testOutput = "$testOutput\n$line";
              }
        });

        testProcess.stderr.transform(new Utf8Decoder())
            .transform(new LineSplitter())
            .listen(
                (String line) => testErrorOutput = "$testErrorOutput\n$line");

        testProcess.exitCode.then((_) => complete());

      });

      // TODO: enable code coverage data gathering when
      //       https://code.google.com/p/dart/issues/detail?id=20293 is fixed.
      // import 'coverage.dart'
    });



    return completer.future;
  }

  /// Starts the HTTP server (pub serve in our case) that's serving the test
  /// files. The Future completes when pub serve is ready to serve files.
  /// If [forceStart] is true then a new instance will be started even if one
  /// has already been started.
  Future<Process> startHttpServer({bool forceStart: false,
                                  Completer<Process> originalCompleter}) {

    // Check if there is already pub serve running (or being started) for this
    // project.
    if (pubServer != null && !forceStart) {
      return pubServer;
    }

    // Start pub serve to serve the test directory of the project.
    var pubServerCompleter = new Completer<Process>();
    // In case of a retry we should use the originalCompleter instead of a new
    // one.
    if (originalCompleter != null) {
      pubServerCompleter = originalCompleter;
    }
    pubServer = pubServerCompleter.future;

    String logs = "";

    Process.start(dartBinaries.pubBin,
                  ["serve", "test", "--port", "$webServerPort"],
                  workingDirectory: dartProject.projectPath).then(
        (Process process) {
          // Log stdout and detect when pub serve is ready.
          process.stdout.transform(new Utf8Decoder())
                        .transform(new LineSplitter())
                        .listen(
              (String line) {
                logs = "$logs$line\n";
                if (line.contains("Build completed")
                    && !pubServerCompleter.isCompleted) {
                  pubServerCompleter.complete(process);
                }
              });

          // Log stderr.
          process.stderr.transform(new Utf8Decoder())
                        .transform(new LineSplitter())
                        .listen(
              (String line) {
            logs = "$logs$line\n";
          });

          // Detect errors/ crash of pub run.
          process.exitCode.then((exitCode) {
            if (exitCode > 0) {
              // If starting the web server failed because the port was already
              // in use we increment it and try again.
              if (logs.contains("Address already in use")) {
                print("Warning: pub serve port $webServerPort already in use.");
                webServerPort = webServerPort +
                    (new math.Random()).nextInt(1000);
                print("Trying to run pub serve with port $webServerPort.");
                startHttpServer(forceStart: true,
                                originalCompleter: pubServerCompleter);
              } else {
                throw new Exception("Pub serve has exited before being ready:"
                                    "\n$logs");
              }
            }
          });
        });

    return pubServer;
  }

  /// Returns the URL that will run the given browser test file.
  String _buildBrowserTestUrl(String testFileName) {
    return "http://$_WEB_SERVER_HOST:$webServerPort/"
           "${GENERATED_TEST_FILES_DIR_NAME}/"
           "${testFileName.replaceFirst(new RegExp(r"\.dart$"), ".html")}";
  }
}
