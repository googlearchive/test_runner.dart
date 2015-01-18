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
  static const _defaultTimeout = const Duration(seconds: 240);

  /// Pointers to all Dart SDK binaries.
  final DartBinaries dartBinaries;

  /// The Dart project containing the tests.
  final DartProject dartProject;

  /// Pool that limits the number of concurrently running tests.
  final Pool _pool;

  /// Constructor. You can specify the maximum number of tests that can run in
  /// parallel with [maxProcesses].
  TestRunnerDispatcher(this.dartBinaries, this.dartProject,
      {int maxProcesses: 4}) : _pool = new Pool(maxProcesses);

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
      var runningTest = _pool.withResource(() => _runTestsWithTimeout(
          testRunner, test, _defaultTimeout).then((TestExecutionResult result) {
        controller.add(result);
      }));

      // Adding the test Future to the list of tests to watch.
      testRunnerResultFutures.add(runningTest);
    }

    // When all tests are completed we close the stream.
    Future.wait(testRunnerResultFutures).then((_) => controller.close());

    return controller.stream;
  }
}

Future<TestExecutionResult> _runTestsWithTimeout(
    TestRunner runner, TestConfiguration testConfiguration, Duration timeout) {
  return runner.runTest(testConfiguration).timeout(timeout, onTimeout: () {
    var testOutput = "The test did not complete in $timeout. It was aborted.";

    return new TestExecutionResult(testConfiguration,
        success: false, testOutput: testOutput);
  });
}
