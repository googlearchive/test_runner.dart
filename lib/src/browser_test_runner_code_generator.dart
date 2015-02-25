// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_runner.browser_test_runner_code_generator;

import 'dart:async';
import 'dart:io';

import 'dart_project.dart';
import 'test_runner_code_generator.dart';

/// Generates the files necessary for the Browser Tests tu run.
class BrowserTestRunnerCodeGenerator extends TestRunnerCodeGenerator {

  /// Constructor.
  BrowserTestRunnerCodeGenerator(DartProject dartProject) : super(dartProject);

  /// Creates the HTML file for the test. If the test does not have a custom
  /// [testHtmlFilePath] then a default one (defined by
  /// [DEFAULT_HTML_TEST_FILE_TEMPLATE_PATH]) will be used to run the browser
  /// test in.
  Future createTestHtmlFile(String testFileName, [String testHtmlFilePath]) {
    return new Future(() {
      if (testHtmlFilePath == null || testHtmlFilePath == "") {
        // If the test does not have an associated test file...
        if (dartProject.customDefaultHtmlPath != null && dartProject.customDefaultHtmlPath.length > 0) {
          // Use the specified default template
          return new File(dartProject.customDefaultHtmlPath).readAsString();
        } else {
          // Use our predefined template
          return _BROWSER_TEST_HTML_FILE_TEMPLATE;
        }
      } else {
        // Custom HTML test files.
        return new File(testHtmlFilePath).readAsString();
      }
    }).then((String htmlFileString) {
      if (testHtmlFilePath == null || testHtmlFilePath == "") {
        var pieces = testFileName.split('/');
        var htmlInclude = pieces.last;
        htmlFileString =
            htmlFileString.replaceAll("{{test_file_name}}", htmlInclude);
      } else {
        // For custom HTML test files we add a call to
        // unittest/test_controller.js and we replace the Dart test file call by
        // the intermediary Dart test file that injects the unittest
        // Configuration.
        if (!htmlFileString.contains("packages/unittest/test_controller.js")) {
          htmlFileString = htmlFileString.replaceFirst("</body>",
              '<script type="text/javascript" '
              'src="/packages/unittest/test_controller.js"></script></body>');
        }
      }

      // Create the file (and delete it if it already exists).
      String generatedFilePath = '${generatedTestFilesDirectory.path}/' +
          '${testFileName.replaceAll(new RegExp(r'\.dart$'), '.html')}';
      File generatedFile = new File(generatedFilePath);
      if (generatedFile.existsSync()) {
        generatedFile.deleteSync();
      }
      generatedFile.createSync(recursive: true);

      // Write into the [File].
      generatedFile.writeAsStringSync(htmlFileString);
    });
  }

  /// Creates the intermediary Dart file that sets the unittest [Configuration].
  Future createTestDartFile(String testFileName) {

    // Read the content for the template Dart file.
    String dartFileString = _BROWSER_TEST_DART_FILE_TEMPLATE;

    // Replaces templated values.
    dartFileString =
        dartFileString.replaceAll("{{test_file_name}}", testFileName);

    // Create the file (and delete it if it already exists).
    String generatedFilePath = '${generatedTestFilesDirectory.path}/'
        '$testFileName';
    File generatedFile = new File(generatedFilePath);

    if (generatedFile.existsSync()) {
      generatedFile.deleteSync();
    }
    generatedFile.createSync(recursive: true);

    // Write into the [File].
    return generatedFile.writeAsString(dartFileString);
  }
}

/// Template of a Dart file that sets the unittest HtmlConfiguration and calls
/// another file's main. You need to replace the `{{test_file_name}}`
/// placeholder with the path to the original test file to execute.
const String _BROWSER_TEST_DART_FILE_TEMPLATE = '''
// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_runner.web_test_config;

import 'package:unittest/html_config.dart';
import '/{{test_file_name}}' as test;

/// Sets the HtmlConfiguration and then calls the original test file.
void main() {
  useHtmlConfiguration();
  test.main();
}
''';

/// Template of a Default HTML file for Browser unittest files that will
/// start the tests in the Dart file written instead of the `{{test_file_name}}`
/// placeholder.
const String _BROWSER_TEST_HTML_FILE_TEMPLATE = '''
<!-- Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
for details. All rights reserved. Use of this source code is governed by a
BSD-style license that can be found in the LICENSE file. -->

<!DOCTYPE html>

<html>
  <head>
    <title>Default Web Test HTML file</title>
    <meta charset="utf-8" />
    <meta name="description" content="Runs a Web test" />
  </head>
  <body>
    <!-- Scripts -->
    <script type="application/dart" src="{{test_file_name}}"></script>
    <script type="text/javascript" src="/packages/unittest/test_controller.js"></script>
  </body>
</html>
''';

