// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_runner.dart_binaries;

import 'dart:async';
import 'dart:io';

/// Holds pointers to Dart SDK binaries and offers convenience methods.
class DartBinaries {

  /// Path to the Content Shell executable.
  String contentShellBin;

  /// Path to the pub executable.
  String pubBin;

  /// Path to the dart2js executable.
  String dart2jsBin;

  DartBinaries(this.contentShellBin, this.pubBin, this.dart2jsBin);

  /// Checks that all the Dart SDK binaries are accessible and working.
  /// If some binaries are not in the PATH a [ArgumentError] will be thrown.
  checkDartSdkBinaries() {
    pubBin = _checkBinary(pubBin, "--pub-bin", "pub", "Pub");
    dart2jsBin = _checkBinary(dart2jsBin, "--dart2js-bin",
        "dart2js", "dart2js");
  }

  /// Checks that all the binaries needed for browser testing are accessible and
  /// working.
  /// If some binaries are not in the PATH a [ArgumentError] will be thrown.
  checkBrowserBinaries() {
    contentShellBin = _checkBinary(contentShellBin, "--content-shell-bin",
        "content_shell", "Content Shell");
  }

  /// Checks if the given [command] is in the PATH and returns the path to the
  /// command.
  String _checkBinary(String command, String cmdAttributeName,
                      String defaultCmd, String programName) {
    ProcessResult whichCmdPr = Process.runSync('which', [command]);
    if (whichCmdPr.exitCode == 0) {
      return whichCmdPr.stdout.trim();
    } else {
      throw new ArgumentError('"$command" is not an executable binary and could'
          ' not be found in the PATH. Please specify the path to the '
          '$programName executable using the ${cmdAttributeName} parameter or '
          'by adding "${defaultCmd}" to the PATH.');
    }
  }

  /// Returns [true] if the Dart file at the given [dartFilePath] needs to be
  /// run in a browser environment.
  Future<bool> isDartFileBrowserOnly(String dartFilePath) {
    Completer<bool> completer = new Completer();
    Process.run(dart2jsBin,
                ["--analyze-only", "--categories=Server", dartFilePath],
                runInShell: true).then((ProcessResult dart2jsPr) {
      // TODO: When dart2js has fixed the issue with their exitcode we should
      //       rely on the exitcode instead of the stdout.
      completer.complete(dart2jsPr.stdout != null
          && (dart2jsPr.stdout as String).contains("Error: Library not found"));
    });
    return completer.future;
  }

}
