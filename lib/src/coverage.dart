// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_runner.coverage;

import 'dart:async';
import 'dart:convert';

import 'package:coverage/src/devtools.dart';
import 'package:coverage/src/util.dart';

/// Listens for an Observatory on the [_observatoryPort] and retrieves the code
/// coverage data when available.
// This is experimental.
// TODO: move code coverage logic to a separate class and build an interface
//       to retrieve code coverage from the TestRunnerDispatcher.
void startCodeCoverageListener(int port) {
  onTimeout() {
    var timeout = 2;
    print('Failed to collect coverage within ${timeout}s');
  }
  Future connected = retry(() => Observatory.connect("127.0.0.1", "$port"),
      new Duration(milliseconds: 100));
  connected.timeout(new Duration(seconds: 2), onTimeout: onTimeout);
  connected.then((observatory) {
    Future ready = new Future.value();
    ready.timeout(new Duration(seconds: 2), onTimeout: onTimeout);

    return ready
        .then((_) => _getAllCoverage(observatory))
        .then(JSON.encode)
        .then((json) {
      // TODO: do something with the result of the gathered code coverage
      //       instead of just printing it.
      print(json);
      observatory.close();
    });
  });
}

/// Returns a JSON object containing code coverage data for all Isolates given
/// an [Observatory].
// This is experimental.
Future<Map> _getAllCoverage(Observatory observatory) {
  return observatory
      .getIsolates()
      .then((isolates) => isolates.map((i) => i.getCoverage()))
      .then(Future.wait)
      .then((responses) {
    // flatten response lists
    var allCoverage = responses.expand((it) => it).toList();
    return {'type': 'CodeCoverage', 'coverage': allCoverage,};
  });
}
