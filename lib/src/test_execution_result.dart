// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_execution_result.dart;

import 'test_configuration.dart';

/// Describes the result of executing a Dart test.
class TestExecutionResult {

  /// Constructor.
  TestExecutionResult(this.test,
      {this.success: true, this.testOutput: "", this.testErrorOutput: ""});

  /// Construct a new [TestExecutionResult] from JSON.
  TestExecutionResult.fromJson(var json, this.test) {
    success = json["success"];
    testOutput = json["testOutput"];
    testErrorOutput = json["testErrorOutput"];
    if (success == null || testOutput == null || testErrorOutput == null) {
      throw new ArgumentError("TestExecutionResult JSON is missing values.");
    }
  }

  /// [true] if the test file succeeded.
  bool success;

  /// What was printed on the standard output by the [UnitTest] library.
  String testOutput;

  /// What was printed on the error output by the [UnitTest] library.
  String testErrorOutput;

  /// Pointer to the test.
  TestConfiguration test;
}
