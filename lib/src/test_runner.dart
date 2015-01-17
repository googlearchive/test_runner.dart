// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'test_configuration.dart';
import 'test_execution_result.dart';

abstract class TestRunner {

  /// Runs the [test] and returns the [TestExecutionResult].
  Future<TestExecutionResult> runTest(TestConfiguration test);
}
