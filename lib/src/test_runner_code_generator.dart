// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_runner.test_runner_code_generator;

import 'dart:io';

import 'dart_project.dart';
import 'util.dart';

/// Provides base class for Code Generators so that they can easily access the
/// Generated test files directory.
abstract class TestRunnerCodeGenerator {

  /// Directory where all the generated test runner files are created.
  final Directory generatedTestFilesDirectory;

  /// Pointers to the Dart Project containing the tests.
  final DartProject dartProject;

  /// Constructor.
  TestRunnerCodeGenerator(DartProject dartProject)
      : this.dartProject = dartProject,
        generatedTestFilesDirectory =
            _createGeneratedTestFilesDirectory(dartProject);

  /// Returns the directory named [GENERATED_TEST_FILES_DIR_NAME] in the
  /// [dartProject]'s test directory and creates it if it doesn't exists.
  ///
  /// Throws a [FileExistsException] if there is already a [FileSystemEntity]
  /// with the same name that's not a [Directory].
  static Directory _createGeneratedTestFilesDirectory(DartProject proj) {
    String generatedTestFilesDirectoryPath =
        proj.testDirectory.resolveSymbolicLinksSync() + "/"
            + GENERATED_TEST_FILES_DIR_NAME;

    Directory newGeneratedSourceDir =
        new Directory(generatedTestFilesDirectoryPath);
    FileSystemEntityType dirType =
        FileSystemEntity.typeSync(generatedTestFilesDirectoryPath);
    if (dirType == FileSystemEntityType.NOT_FOUND) {
      newGeneratedSourceDir.createSync();
    } else if (dirType != FileSystemEntityType.DIRECTORY) {
      throw new FileExistsException("$generatedTestFilesDirectoryPath already "
          "exists and is not a Directory.");
    }
    return newGeneratedSourceDir;
  }

  /// Deletes the Generated test files directory of a given [dartProject].
  ///
  /// Returns [True] if a directory existed and was deleted and [False] if there
  /// was no directory.
  static bool deleteGeneratedTestFilesDirectory(DartProject dartProject) {
    String generatedTestFilesDirectoryPath =
        dartProject.testDirectory.resolveSymbolicLinksSync() + "/"
            + GENERATED_TEST_FILES_DIR_NAME;

    Directory newGeneratedSourceDir =
        new Directory(generatedTestFilesDirectoryPath);

    if (newGeneratedSourceDir.existsSync()) {
      newGeneratedSourceDir.deleteSync(recursive: true);
      return true;
    }
    return false;
  }
}

/// Exception used if a file exists that was not supposed to.
class FileExistsException extends Exception {
  factory FileExistsException([var message]) => new Exception(message);
}
