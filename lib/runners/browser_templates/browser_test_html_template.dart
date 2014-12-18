// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of test_runner.runner;

/// Template of a Default HTML file for Browser unittest files that will
/// start the tests in the Dart file written instead of the `{{test_file_name}}`
/// placeholder.
const String BROWSER_TEST_HTML_FILE_TEMPLATE = '''
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
    <script type="application/dart" src="./{{test_file_name}}"></script>
    <script type="text/javascript" src="./packages/unittest/test_controller.js"></script>
  </body>
</html>
''';
