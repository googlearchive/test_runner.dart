// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of test_runner.runner;

/// Template of a Dart file that sets the unittest HtmlConfiguration and calls
/// another file's main. You need to replace the `{{test_file_name}}`
/// placeholder with the path to the original test file to execute.
const String BROWSER_TEST_DART_FILE_TEMPLATE = '''
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
