// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_runner.vm_test_runner_code_generator;

import 'dart:async';
import 'dart:io';

import 'package:unittest/unittest.dart';

import 'dart_project.dart';
import 'test_runner_code_generator.dart';

/// Generates the files necessary for the Browser Tests to run.
class VmTestRunnerCodeGenerator extends TestRunnerCodeGenerator {

  /// Constructor.
  VmTestRunnerCodeGenerator(DartProject dartProject) : super(dartProject);

  /// Creates the intermediary Dart file that sets the unittest [Configuration].
  Future createTestDartFile(String testFileName) {
    // Read the content fo the template Dart file.
    String dartFileString = _VM_TEST_DART_FILE_TEMPLATE;
    if (dartProject.customVmDartTemplatePath != null && dartProject.customVmDartTemplatePath.length > 0) {
      dartFileString = new File(dartProject.customVmDartTemplatePath).readAsStringSync();
    }

    // Replaces templated values.
    dartFileString =
        dartFileString.replaceAll("{{test_file_name}}", testFileName);
    String pathDepth = testFileName.split(Platform.pathSeparator)
        .fold("", (String value, _) => "$value../");
    dartFileString =
        dartFileString.replaceAll("{{test_file_import}}", pathDepth + testFileName);

    // Create the file (and delete it if it already exists).
    String generatedFilePath =
        '${generatedTestFilesDirectory.path}/' + '$testFileName';
    File generatedFile = new File(generatedFilePath);
    if (generatedFile.existsSync()) {
      generatedFile.deleteSync();
    }
    generatedFile.createSync(recursive: true);

    // Write into the [File].
    return generatedFile.writeAsString(dartFileString);
  }
}

/// Template of a Dart file that sets the unittest VmConfiguration and calls
/// another file's main. You need to replace the `{{test_file_name}}`
/// placeholder with the path to the original test file to execute.
const String _VM_TEST_DART_FILE_TEMPLATE = '''
// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_runner.vm_test_config;

import 'package:unittest/vm_config.dart';
import '{{test_file_import}}' as test;

/// Sets the VmConfiguration and then calls the original test file.
void main() {
  useVMConfiguration();
  test.main();
}
''';
