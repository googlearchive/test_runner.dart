// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_runner.alias;

import 'run_tests.dart' as original;

/// This is an alias to run_tests.dart to make it easy to run the tool with `pub
/// global`.
main(arguments) => original.main(arguments);
