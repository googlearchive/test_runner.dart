// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of test_runner.runner;

/// Runs Dart tests that can be run in a web browser.
class BrowserTestRunner extends TestRunner {

  /// Port to be used by the [WebServer] serving the test files.
  // TODO: randomize port if already used.
  static const int WEB_SERVER_PORT = 7478;

  /// Port to be used by the [WebServer] serving the test files.
  // TODO: randomize port if already used instead of incrementing.
  static int observatoryPort = 8887;

  /// Host to be used by the [WebServer] serving the test files.
  static const String WEB_SERVER_HOST = "127.0.0.1";

  /// Points to the [Completer]s that will indicate if pub serve is ready for a
  /// given project absolute path.
  static Map<String, Completer> pubServerCompleters = new Map();

  /// Pointers to all Dart SDK binaries.
  final DartBinaries dartBinaries;

  /// Pointers to the Dart Project containing the tests.
  final DartProject dartProject;

  /// Constructor.
  BrowserTestRunner(this.dartBinaries, this.dartProject);

  @override
  Future<TestExecutionResult> runTest(TestConfiguration test) {

    Completer<TestExecutionResult> completer = new Completer();

    // Create the temporary generated test files.
    BrowserTestRunnerCodeGenerator codeGenerator =
        new BrowserTestRunnerCodeGenerator(dartProject);
    Future htmlFileFuture = codeGenerator.createTestHtmlFile(test.testFileName,
        (test.testType as BrowserTest).htmlFilePath);
    Future dartFileFuture = codeGenerator.createTestDartFile(test.testFileName);

    // Start the Web Server and run the test.
    Future httpServer = _startHttpServer();

    // Runs the Web Test in Content Shell when the files have been created and
    // when all the test files have been generated.
    Future.wait([htmlFileFuture, dartFileFuture, httpServer]).then((_) {

      String testUrl = buildBrowserTestUrl(test.testFileName);

      // TODO: Have a timer stop this after a fixed amount of time.
      Process
          .run(dartBinaries.contentShellBin,
              ["--args", "--dump-render-tree", "--disable-gpu",
               "--remote-debugging-port=$observatoryPort",
               testUrl], runInShell: false)
          .then(
              (ProcessResult testProcessResult) {
                if (testProcessResult.stdout.contains("#CRASHED")) {
                  throw new Exception("Error: Content shell crashed.");
                }
                TestExecutionResult result = new TestExecutionResult(test);
                result.success = testProcessResult.stdout.contains("PASS\n");
                result.testOutput = testProcessResult.stdout
                    .replaceAll("#EOF", "")
                    .replaceAll("#READY", "")
                    .replaceAll("CONSOLE MESSAGE: Warning: The "
                        "unittestConfiguration has already been set. New "
                        "unittestConfiguration ignored.", "")
                    .replaceAll("Content-Type: text/plain", "");
                result.testErrorOutput = testProcessResult.stderr
                    .replaceAll("#EOF", "");
                completer.complete(result);
              }
      );

      // TODO: enable code coverage data gathering when
      //       https://code.google.com/p/dart/issues/detail?id=20293 is fixed.
      //startCodeCoverageListener();
      observatoryPort++;
    });

    return completer.future;
  }

  /// Starts the HTTP server (pub serve in our case) that's serving the test
  /// files. The Future completes when pub serve is ready to serve files.
  Future _startHttpServer() {

    // Check if there is already pub serve running (or being started) for this
    // project.
    Completer pubServerCompleter =
        pubServerCompleters[dartProject.testDirectory.path];

    if (pubServerCompleter != null) {
      return pubServerCompleter.future;
    }

    // Start pub serve to serve the test directory of the project.
    pubServerCompleter = new Completer();
    pubServerCompleters[dartProject.testDirectory.path] = pubServerCompleter;

    Process.start(dartBinaries.pubBin,
                  ["serve", "test", "--port", "$WEB_SERVER_PORT"],
                  workingDirectory: dartProject.projectPath).then(
        (Process process) {
          process.stdout.transform(new Utf8Decoder())
                        .transform(new LineSplitter())
                        .listen(
              (String line) {
                if (line.contains("Build completed")
                    && !pubServerCompleter.isCompleted) {
                  pubServerCompleter.complete();
                }
              });
        });

    return pubServerCompleter.future;
  }

  /// Returns the URL that will run the given browser test file.
  String buildBrowserTestUrl(String testFileName) {
    return "http://$WEB_SERVER_HOST:$WEB_SERVER_PORT/"
        "${TestRunnerCodeGenerator.GENERATED_TEST_FILES_DIR_NAME}/"
        "${testFileName.replaceFirst(new RegExp(r"\.dart$"), ".html")}";
  }

  /// Listens for an Observatory on the [observatoryPort] and retrieves the code
  /// coverage data when available.
  // This is experimental.
  // TODO: move code coverage logic to a separate class and build an interface
  //       to retrieve code coverage from the TestRunnerDispatcher.
  void startCodeCoverageListener() {

    var port = observatoryPort;

    onTimeout() {
      var timeout = 2;
      print('Failed to collect coverage within ${timeout}s');
    }
    Future connected = retry(() => Observatory.connect("127.0.0.1", "$port"),
        new Duration(milliseconds:100));
    connected.timeout(new Duration(seconds:2), onTimeout: onTimeout);
    connected.then((observatory) {
      Future ready = new Future.value();
      ready.timeout(new Duration(seconds:2), onTimeout: onTimeout);

      return ready.then((_) => getAllCoverage(observatory))
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
  static Future<Map> getAllCoverage(Observatory observatory) {
    return observatory.getIsolates()
    .then((isolates) => isolates.map((i) => i.getCoverage()))
    .then(Future.wait)
    .then((responses) {
      // flatten response lists
      var allCoverage = responses.expand((it) => it).toList();
      return {
          'type': 'CodeCoverage',
          'coverage': allCoverage,
      };
    });
  }
}

/// Generates the files necessary for the Browser Tests tu run.
class BrowserTestRunnerCodeGenerator extends TestRunnerCodeGenerator {

  /// Constructor.
  BrowserTestRunnerCodeGenerator(dartProject) : super(dartProject);

  /// Creates the HTML file for the test. If the test does not have a custom
  /// [testHtmlFilePath] then a default one (defined by
  /// [DEFAULT_HTML_TEST_FILE_TEMPLATE_PATH]) will be used to run the browser
  /// test in.
  Future createTestHtmlFile(String testFileName, [String testHtmlFilePath]) {
    Completer completer = new Completer();

    Future<String> htmlFileReader;

    if (testHtmlFilePath == null || testHtmlFilePath == "") {
      // If the test does not have an associated test file we'll call the test
      // file inside of a default HTML file.
      htmlFileReader = (new Completer<String>()
          ..complete(BROWSER_TEST_HTML_FILE_TEMPLATE)).future;

    } else {
      // Custom HTML test files.
      htmlFileReader = new File(testHtmlFilePath).readAsString();
    }

    // Read the content of the file.
    htmlFileReader.then((String htmlFileString) {

      if (testHtmlFilePath == null || testHtmlFilePath == "") {
        htmlFileString =
            htmlFileString.replaceAll("{{test_file_name}}", testFileName);

      } else {
        // For custom HTML test files we add a call to
        // unittest/test_controller.js and we replace the Dart test file call by
        // the intermediary Dart test file that injects the unittest
        // Configuration.
        if (!htmlFileString.contains("packages/unittest/test_controller.js")) {
          htmlFileString = htmlFileString.replaceFirst(
              "</body>", '<script type="text/javascript" '
              'src="packages/unittest/test_controller.js"></script></body>');
        }
      }

      // Create the file (and delete it if it already exists).
      String generatedFilePath = '${generatedTestFilesDirectory.path}/'
          + '${testFileName.replaceAll(new RegExp(r'\.dart$'), '.html')}';
      File generatedFile = new File(generatedFilePath);
      if (generatedFile.existsSync()) {
        generatedFile.deleteSync();
      }
      generatedFile.createSync(recursive: true);

      // Write into the [File].
      generatedFile.writeAsStringSync(htmlFileString);
      completer.complete();
    });

    return completer.future;
  }

  /// Creates the intermediary Dart file that sets the unittest [Configuration].
  Future createTestDartFile(String testFileName) {

    // Read the content fo the template Dart file.
    String dartFileString = BROWSER_TEST_DART_FILE_TEMPLATE;

    // Replaces templated values.
    dartFileString =
        dartFileString.replaceAll("{{test_file_name}}", testFileName);

    // Create the file (and delete it if it already exists).
    String generatedFilePath = '${generatedTestFilesDirectory.path}/'
        '$testFileName';
    File generatedFile = new File(generatedFilePath);

    if (generatedFile.existsSync()) {
      generatedFile.deleteSync();
    }
    generatedFile.createSync(recursive: true);

    // Write into the [File].
    return generatedFile.writeAsString(dartFileString);
  }
}
