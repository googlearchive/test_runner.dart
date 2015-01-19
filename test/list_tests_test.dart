// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_runner.list_tests_test;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:scheduled_test/descriptor.dart' as d;
import 'package:scheduled_test/scheduled_test.dart';

import 'package:test_runner/test_runner.dart';

import 'test_util.dart';

void main() {
  test('find tests', () {
    DartProject project;
    DartBinaries binaries;

    schedule(() {
      binaries = new DartBinaries.withDefaults();
      binaries.checkDartSdkBinaries();
    });

    schedule(() {
      return createTempDir().then((value) {
        d.defaultRoot = value.path;
      });
    });

    d.dir('proj', [
      d.file('pubspec.yaml', unittestPubspec),
      d.dir('test', [
        d.file('simple_ok_test.dart', getTestFile()),
        d.file('simple_fail_test.dart', getTestFile(shouldSucceed: false)),
        d.dir('subdir_tests', [
          d.file('sub_ok_test.dart', getTestFile()),
          d.file('sub_fail_test.dart', getTestFile(shouldSucceed: false)),
        ])
      ])
    ]).create();

    schedule(() {
      var projPath = p.join(d.defaultRoot, 'proj');
      project = new DartProject(projPath, binaries);
      project.checkProject();
    });

    schedule(() {
      return Process.run('pub', ['get', '--offline'],
          workingDirectory: project.projectPath).then((pr) {
        expect(pr.exitCode, 0, reason: 'pub get should succeed');
      });
    });

    Map<String, TestConfiguration> tests;

    schedule(() {
      return project.findTests([]).toList().then((value) {
        tests = _getTestMap(value);
      });
    });

    schedule(() {
      expect(tests, hasLength(4));

      var config = tests['simple_ok_test.dart'];
      expect(config.testType is VmTest, isTrue);

      config = tests['simple_fail_test.dart'];
      expect(config.testType is VmTest, isTrue);

      config = tests['subdir_tests/sub_ok_test.dart'];
      expect(config.testType is VmTest, isTrue);

      config = tests['subdir_tests/sub_fail_test.dart'];
      expect(config.testType is VmTest, isTrue);
    });
  });
}

Map<String, TestConfiguration> _getTestMap(List<TestConfiguration> tests) {
  var map = <String, TestConfiguration>{};

  if (tests.isNotEmpty) {
    var testDir = p.join(tests.first.dartProject.projectPath, 'test');
    testDir = new Directory(testDir).resolveSymbolicLinksSync();

    for (var t in tests) {
      var testPath = t.testFilePath;

      expect(p.isWithin(testDir, testPath), isTrue,
          reason: 'Each test file should be in the project test directory.');

      testPath = p.relative(testPath, from: testDir);

      map[testPath] = t;
    }
  }

  return map;
}
