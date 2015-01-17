// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:pool/pool.dart';

import 'browser_test_runner.dart';
import 'dart_binaries.dart';
import 'dart_project.dart';
import 'test_configuration.dart';
import 'test_execution_result.dart';
import 'test_runner.dart';
import 'vm_test_runner.dart';

/// Properly dispatch running tests to the correct [TestRunner].
class TestRunnerDispatcher {

  /// Number of seconds to wait until the test times out.
  static const int TESTS_TIMEOUT_SEC = 240;

  /// Pointers to all Dart SDK binaries.
  DartBinaries dartBinaries;

  /// The Dart project containing the tests.
  DartProject dartProject;

  /// Pool that limits the number of concurrently running tests.
  Pool pool;

  /// Constructor. You can specify the maximum number of tests that can run in
  /// parallel with [maxProcesses].
  TestRunnerDispatcher(this.dartBinaries, this.dartProject,
      {int maxProcesses: 4}) {
    pool = new Pool(maxProcesses);
  }

  /// Runs all the given [tests].
  ///
  /// TODO: Implement @NotParallelizable
  Stream<TestExecutionResult> runTests(List<TestConfiguration> tests) {

    // We create a Stream so that we can display in real time results of tests
    // that completed.
    StreamController<TestExecutionResult> controller =
        new StreamController<TestExecutionResult>.broadcast();

    // We list the futures so that we can wait for all of them to complete in
    // order to close the Stream.
    List<Future<TestExecutionResult>> testRunnerResultFutures =
        new List<Future<TestExecutionResult>>();

    // For each Test we find the correct TestRunner and run the test with it.
    for (TestConfiguration test in tests) {
      TestRunner testRunner;
      if (test.testType is VmTest) {
        testRunner = new VmTestRunner(dartBinaries, dartProject);
      } else if (test.testType is BrowserTest) {
        testRunner = new BrowserTestRunner(dartBinaries, dartProject);
      }

      // Execute test and send result to the stream.
      Future<TestExecutionResult> stuff = pool.withResource(() =>
          testRunner.runTest(test)
              // Kill the test after a set amount of time. Timeout.
              .timeout(new Duration(seconds: TESTS_TIMEOUT_SEC), onTimeout: () {
                TestExecutionResult result = new TestExecutionResult(test);
                result.success = false;
                result.testOutput = "The test did not complete in less than "
                                    "$TESTS_TIMEOUT_SEC seconds. "
                                    "It was aborted.";
                return result;
              })..then((TestExecutionResult result) {
                controller.add(result);
          }));

      // Adding the test Future to the list of tests to watch.
      testRunnerResultFutures.add(stuff);
    }

    // When all tests are completed we close the stream.
    Future.wait(testRunnerResultFutures).then((_) => controller.close());

    return controller.stream;
  }
}

