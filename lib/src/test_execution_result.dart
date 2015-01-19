// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_runner.test_execution_result;

import 'test_configuration.dart';

/// Describes the result of executing a Dart test.
class TestExecutionResult {

  /// Constructor.
  TestExecutionResult(this.test,
      {this.success: true, this.testOutput: "", this.testErrorOutput: ""});

  /// Construct a new [TestExecutionResult] from JSON.
  factory TestExecutionResult.fromJson(
      Map<String, dynamic> json, TestConfiguration test) {
    var success = json["success"];
    var testOutput = json["testOutput"];
    var testErrorOutput = json["testErrorOutput"];
    if (success == null || testOutput == null || testErrorOutput == null) {
      throw new ArgumentError("TestExecutionResult JSON is missing values.");
    }

    return new TestExecutionResult(test,
        success: success,
        testOutput: testOutput,
        testErrorOutput: testErrorOutput);
  }

  /// [true] if the test file succeeded.
  final bool success;

  /// What was printed on the standard output by the [UnitTest] library.
  final String testOutput;

  /// What was printed on the error output by the [UnitTest] library.
  final String testErrorOutput;

  /// Pointer to the test.
  final TestConfiguration test;
}
