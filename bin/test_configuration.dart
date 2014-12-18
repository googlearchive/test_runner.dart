// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of test_runner;

// The classes below used as annotations to configure test files.

/// Common abstract class for all test types.
abstract class Test {
  const Test();
}

/// Indicate that the test is to be ran in a Browser environment. This should be
/// used to annotate a test file [main] function.
///
/// The [browser] with which the file can be ran can be specified. You can also
/// Specify an [htmlFilePath] which points to an HTML file that will be used to
/// run the test (it should be importing the test dart file).
///
/// Note: a single test can be annotated multiple times with [BrowserTest] and
/// [VmTest]. If so then the test will be ran multiple times with the different
/// setup.
// TODO need to implement annotation extraction
class BrowserTest extends Test {

  /// On which browser should this test be ran.
  final Symbol browser;

  /// Path to the associated HTML file that will run the test.
  final String htmlFilePath;

  /// [True] if the test should be ran without transformers.
  // TODO need to implement this behavior
  final bool disableTransformers;

  /// Enum for the Dartium browser which is currently the only supported browser
  /// on which to run tests.
  // TODO implement more browser support
  static const Symbol DARTIUM_BROWSER = #dartium;

  const BrowserTest({this.disableTransformers: false,
                    this.browser: DARTIUM_BROWSER,
                    this.htmlFilePath: null});
}

/// Indicates that the test is to be ran in a  Server side/Command line
/// environment. This should be used to annotate a test file [main] function.
///
/// Note: a single test can be annotated multiple times with [BrowserTest] and
/// [VmTest]. If so then the test will be ran multiple times with the different
/// setup.
// TODO need to implement annotation extraction
class VmTest extends Test {

  /// [True] if the test should be ran without transformers.
  // TODO need to implement this behavior
  final bool disableTransformers;

  const VmTest({this.disableTransformers: false});
}

/// Annotate a test main function if the test can't be run in parallel to other.
/// For example if it uses database read/write conflicting with other tests.
// TODO need to implement this behavior
class NotParallelizable {
  const NotParallelizable();
}

/// Annotate a test main function if the test is supposed to fail. For example
/// in the case of Test-driven development.
// TODO need to implement this behavior
class ShouldFail {
  const ShouldFail();
}

/// Describes a test and its configuration like:
///  - Path of the test file
///  - How should the test be ran (in browser, command line)
class TestConfiguration {

  // Test Attributes.

  /// Path to the test file to be ran.
  final String testFilePath;

  /// Type of the test (e.g. [VmTest] or [BrowserTest])
  final Test testType;

  /// True if the test can be ran in parallel to other tests
  final bool parallelizable;

  /// Pointer to the Dart project containing the test.
  final DartProject dartProject;

  /// True if the test run should fail.
  final bool shouldFail;

  TestConfiguration(this.testFilePath, this.dartProject,
                    {this.testType: const VmTest(), this.parallelizable: true,
                    this.shouldFail: false}) {
  }

  /// Path of the test file relative to the test directory.
  String get testFileName {
    String absFilePath = new File(testFilePath).resolveSymbolicLinksSync();
    String absDirPath = dartProject.testDirectory.resolveSymbolicLinksSync();
    return absFilePath.replaceFirst("$absDirPath/", "");
  }
}
