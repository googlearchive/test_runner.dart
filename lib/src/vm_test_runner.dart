// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_runner.vm_test_runner;

import 'dart:async';
import 'dart:io';

import 'dart_binaries.dart';
import 'dart_project.dart';
import 'test_configuration.dart';
import 'test_execution_result.dart';
import 'test_runner.dart';
import 'util.dart';
import 'vm_test_runner_code_generator.dart';

/// Runs Dart tests that can be run in the command line/VM.
class VmTestRunner extends TestRunner {

  /// Pointers to all Dart SDK binaries.
  final DartBinaries dartBinaries;

  /// Pointers to the Dart Project containing the tests.
  final DartProject dartProject;

  /// Constructor.
  VmTestRunner(this.dartBinaries, this.dartProject);

  @override
  Future<TestExecutionResult> runTest(TestConfiguration test) {

    // Generate the file that will force the [VmTestConfiguration] for unittest.
    VmTestRunnerCodeGenerator codeGenerator =
        new VmTestRunnerCodeGenerator(dartProject);
    codeGenerator.createTestDartFile(test.testFileName);

    Process.runSync(dartBinaries.pubBin, ["get", "--offline"]);

    String newTestFilePath =
        "./test/" + GENERATED_TEST_FILES_DIR_NAME + "/" + test.testFileName;

    return Process
        .run(dartBinaries.dartBin, [newTestFilePath],
            runInShell: false, workingDirectory: dartProject.projectPath)
        .then((ProcessResult testProcess) {
      var success = testProcess.exitCode == 0;
      var testOutput =
          testProcess.stdout.replaceAll("unittest-suite-wait-for-done", "");
      var testErrorOutput = testProcess.stderr;

      return new TestExecutionResult(test,
          success: success,
          testOutput: testOutput,
          testErrorOutput: testErrorOutput);
    });
  }
}
