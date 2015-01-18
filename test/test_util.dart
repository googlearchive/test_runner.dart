// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_runner.test_util;

import 'dart:async';
import 'dart:io';

import 'package:scheduled_test/scheduled_test.dart';

String getTestFile({bool shouldSucceed: true}) {
  return _testFileTemplate
      .replaceAll('{{should_succeed}}', shouldSucceed.toString())
      .replaceAll('{{import_config}}', '')
      .replaceAll('{{use_config}}', '');
}

const _testFileTemplate = '''
import 'package:unittest/unittest.dart';
{{import_config}}

void main() {
  {{use_config}}
  test('test case', () {
    expect({{should_succeed}}, isTrue);
  });
}
''';

const unittestPubspec = '''
name: foo
dev_dependencies:
  unittest: ">=0.11.4 <0.12.0"
''';

Future<Directory> createTempDir([bool scheduleDelete = true]) {
  var ticks = new DateTime.now().toUtc().millisecondsSinceEpoch;
  return Directory.systemTemp.createTemp('test_runner.$ticks.').then((dir) {
    currentSchedule.onComplete.schedule(() {
      if (scheduleDelete) {
        return dir.delete(recursive: true);
      } else {
        print('Not deleting $dir');
      }
    });

    return dir;
  });
}
