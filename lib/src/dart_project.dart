// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_runner.dart_project;

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pool/pool.dart';
import 'package:yaml/yaml.dart';

import 'dart_binaries.dart';
import 'test_configuration.dart';
import 'util.dart';

/// Represents a Dart project
class DartProject {
  static const String TEST_FILE_SUFFIX = "_test.dart";

  /// Pointer to the dart binaries.
  DartBinaries dartBinaries;

  /// Path to the root of the Dart project.
  String projectPath;

  Directory _testDirectory;

  /// The project's test folder [Directory].
  Directory get testDirectory => _testDirectory;

  /// YAML data of the pubspec.yaml file.
  Map pubSpecYaml;

  /// True if the `packages` folder exists.
  bool packagesFolderExists;

  /// Pool that limits the number of concurrently running tests.
  final Pool _pool;

  /// Constructor. You can specify the maximum number of tests detection
  /// processes that can run in parallel with [maxProcesses].
  DartProject(this.projectPath, this.dartBinaries, {int maxProcesses: 4})
      : _pool = new Pool(maxProcesses);

  /// Check if a Dart project can be found in [projectPath] and loads its
  /// pubspec.yaml values into [pubSpecYaml].
  void checkProject() {
    if (!DartProject.isProjectPath(projectPath)) {
      throw new StateError("$projectPath is not a valid project path");
    }

    // Save the absolute directory and path.
    Directory projectDirectory = new Directory(projectPath);

    projectPath = projectDirectory.path;
    var pubSpecFile = new File(p.join(projectPath, 'pubspec.yaml'));

    try {
      pubSpecYaml = loadYaml(pubSpecFile.readAsStringSync());
    } catch (e) {
      throw new ArgumentError('There was an error reading the "pubspec.yaml" '
          'file of the project: $e');
    }

    // Check if the `packages` folder exists.
    packagesFolderExists = FileSystemEntity.typeSync(
        p.join(projectPath, 'packages')) == FileSystemEntityType.DIRECTORY;
  }

  static bool isProjectPath(String path) {
    var projPathType = FileSystemEntity.typeSync(path);

    if (projPathType == FileSystemEntityType.NOT_FOUND) {
      throw new ArgumentError('The "${new File(path).absolute.path}" '
      'directory does not exist.');
    }

    if (projPathType != FileSystemEntityType.DIRECTORY) {
      throw new ArgumentError("\"$path\" is not a directory.");
    }

    var pubSpecFile = new File(p.join(path, 'pubspec.yaml'));

    if (!pubSpecFile.existsSync()) {
      throw new ArgumentError('"$path" is not a Dart project directory.'
      ' Could not find the "pubspec.yaml" file.');
    }

    return true;
  }

  /// Finds all the tests in the project and reads their configuration and lists
  /// them in [tests].
  ///
  /// A test must be located in the "test" directory of the project and must
  /// either:
  ///  - Import 'package:unittest/unittest.dart' and have a main() function
  ///  - have a main function annotated with a [BrowserTest] or [VmTest]
  Stream<TestConfiguration> findTests(List<String> testPaths) {
    StreamController<TestConfiguration> controller =
        new StreamController.broadcast();

    var testConfFutureList = new List<Future<TestConfiguration>>();

    try {
      var testDirPath =
          new Directory(p.join(projectPath, 'test')).resolveSymbolicLinksSync();
      _testDirectory = new Directory(testDirPath);
    } catch (e) {
      // No "test" folder so no tests to run.
      controller.close();
      return controller.stream;
    }

    // Will list all files to be analyzed.
    List<FileSystemEntity> files = new List();

    // Special case if the user has manually specified a list of tests to run.
    if (testPaths.length != 0) {
      for (String testPath in testPaths) {
        if (FileSystemEntity.isDirectorySync(testPath)) {
          new Directory(testPath)
            .listSync(recursive: true, followLinks: false)
            .forEach((FileSystemEntity entity) {
            if (entity is File) {
              if (entity.path.endsWith(TEST_FILE_SUFFIX)) {
                files.add(_checkTestPath(entity.path));
              } else {
                print('\nNotice: ignoring non-test file ${entity.path}');
              }
            }
          });
        } else {
          files.add(_checkTestPath(testPath));
        }
      }
    } else {
      // List files in the "test" folder.
      files = testDirectory.listSync(recursive: true, followLinks: false);
    }

    // Check if the files listed could be a Dart test and extract each test
    // configuration.
    for (FileSystemEntity file in files) {
      Future<TestConfiguration> testConfFuture = _pool.withResource(
          () => _extractTestConf(file).then((TestConfiguration testConf) {
        if (testConf != null) {
          controller.add(testConf);
        }
      }));
      testConfFutureList.add(testConfFuture);
    }

    // Notify the StreamController when all testConfig have been extracted.
    Future.wait(testConfFutureList).then((_) => controller.close());
    return controller.stream;
  }

  File _checkTestPath(String testPath) {
    if (!testPath.endsWith(TEST_FILE_SUFFIX)) {
      throw new ArgumentError('The "$testPath" file does not seem to be a'
      ' test Dart file. Test Dart files should have a "_test.dart" '
      'suffix');
    } else if (FileSystemEntity.isFileSync(testPath)) {
      File testFile = new File(testPath);
      if (testFile.absolute.path.indexOf(testDirectory.absolute.path) != 0) {
        throw new ArgumentError('The "$testPath" test file is not located'
        " in the current Dart project's test directory: " +
        testDirectory.path);
      } else {
        return testFile;
      }
    } else {
      throw new ArgumentError('The "$testPath" file does not exist.');
    }
  }

  /// Extracts the given test [file]'s configuration. If the [file] is not a
  /// test [null] is returned.
  // TODO: add annotation extraction to configure tests.
  Future<TestConfiguration> _extractTestConf(FileSystemEntity file) {

    // Make sure [file] is an actual Dart test file.
    if (!FileSystemEntity.isFileSync(file.path) ||
        !file.path.endsWith(TEST_FILE_SUFFIX) ||
        file.path
            .contains(GENERATED_TEST_FILES_DIR_NAME + Platform.pathSeparator)) {
      return new Future.value();
    }

    // Checking if there is an associated HTML file in which case this is a
    // Browser Test.
    String potentialHtmlFilePath =
        file.path.substring(0, file.path.length - 5) + ".html";
    if (FileSystemEntity.typeSync(potentialHtmlFilePath) ==
        FileSystemEntityType.FILE) {
      var testConfiguration = new TestConfiguration(file.path, this,
          testType: new BrowserTest(htmlFilePath: potentialHtmlFilePath));

      return new Future.value(testConfiguration);
    } else {
      // We check that the test is a Browser Test using dart2js as it may not
      // have an attached HTML file.
      return dartBinaries.isDartFileBrowserOnly(file.path).then(
          (bool isBrowser) {
            if (isBrowser) {
              return new TestConfiguration(file.path, this,
                  testType: new BrowserTest());
            } else {
              return new TestConfiguration(file.path, this);
            }
      });
    }
  }
}
