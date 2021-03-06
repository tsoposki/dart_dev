// Copyright 2015 Workiva Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

library dart_dev.src.tasks.coverage.api;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_dev/util.dart' show Reporter, TaskProcess, getOpenPort;
import 'package:path/path.dart' as path;

import 'package:dart_dev/src/tasks/coverage/config.dart';
import 'package:dart_dev/src/tasks/task.dart';

const String _testFilePattern = '_test.dart';

class CoverageResult extends TaskResult {
  final File collection;
  final Directory report;
  final File reportIndex;
  final File lcov;
  final Iterable<String> tests;

  CoverageResult.fail(
      Iterable<String> this.tests, File this.collection, File this.lcov,
      {Directory report})
      : super.fail(),
        this.report = report,
        reportIndex = report != null
            ? new File(path.join(report.path, 'index.html'))
            : null;

  CoverageResult.success(
      Iterable<String> this.tests, File this.collection, File this.lcov,
      {Directory report})
      : super.success(),
        this.report = report,
        reportIndex = report != null
            ? new File(path.join(report.path, 'index.html'))
            : null;
}

class CoverageTask extends Task {
  /// Collect and format coverage for the given suite of [tests]. The result of
  /// the coverage task will be returned once it has completed.
  ///
  /// Each file path in [tests] will be run as a test. Each directory path in
  /// [tests] will be searched (recursively) for all files ending in
  /// "_test.dart" and all matching files will be run as tests.
  ///
  /// If [html] is true, `genhtml` will be used to generate an HTML report of
  /// the collected coverage and the report will be opened.
  static Future<CoverageResult> run(List<String> tests,
      {bool html: defaultHtml,
      String output: defaultOutput,
      List<String> reportOn: defaultReportOn}) async {
    CoverageTask coverage =
        new CoverageTask._(tests, html: html, output: output);
    await coverage._collect();
    await coverage._format(reportOn);

    if (html) {
      await coverage._generateReport();
    }
    return new CoverageResult.success(
        coverage.tests, coverage.collection, coverage.lcov,
        report: coverage.report);
  }

  /// Collect and format coverage for the given suite of [tests]. The
  /// [CoverageTask] instance will be returned as soon as it is started. Output
  /// from the sub tasks will be available in stream format so that immediate
  /// progress can be monitored. The result of the coverage task will be
  /// available from the `done` Future on the task.
  ///
  /// Each file path in [tests] will be run as a test. Each directory path in
  /// [tests] will be searched (recursively) for all files ending in
  /// "_test.dart" and all matching files will be run as tests.
  ///
  /// If [html] is true, `genhtml` will be used to generate an HTML report of
  /// the collected coverage and the report will be opened.
  static CoverageTask start(List<String> tests,
      {bool html: defaultHtml,
      String output: defaultOutput,
      List<String> reportOn: defaultReportOn}) {
    CoverageTask coverage =
        new CoverageTask._(tests, html: html, output: output);

    // Execute the coverage collection and formatting, but don't wait on it.
    () async {
      await coverage._collect();
      await coverage._format(reportOn);

      if (html) {
        await coverage._generateReport();
      }
      CoverageResult result = new CoverageResult.success(
          coverage.tests, coverage.collection, coverage.lcov,
          report: coverage.report);
      coverage._done.complete(result);
    }();

    return coverage;
  }

  /// JSON formatted coverage. Output from the coverage package.
  File _collection;

  /// Combination of the underlying process stdouts.
  StreamController<String> _coverageOutput = new StreamController();

  /// Combination of the underlying process stderrs.
  StreamController<String> _coverageErrorOutput = new StreamController();

  /// Completes when collection, formatting, and report generation is finished.
  Completer<CoverageResult> _done = new Completer();

  /// LCOV formatted coverage.
  File _lcov;

  /// List of test files to run and collect coverage from. This list is
  /// generated from the given list of test paths by adding all files and
  /// searching all directories for valid test files.
  List<File> _files = [];

  /// File created to run the test in a browser. Need to store it so it can be
  /// cleaned up after the test finishes.
  File _lastHtmlFile;

  /// Process used to run the tests. Need to store it so it can be killed after
  /// the coverage collection has completed.
  TaskProcess _lastTestProcess;

  /// Directory to output all coverage related artifacts.
  Directory _outputDirectory;

  CoverageTask._(List<String> tests,
      {bool html: defaultHtml, String output: defaultOutput})
      : _outputDirectory = new Directory(output) {
    // Build the list of test files.
    tests.forEach((path) {
      if (path.endsWith(_testFilePattern) &&
          FileSystemEntity.isFileSync(path)) {
        _files.add(new File(path));
      } else if (FileSystemEntity.isDirectorySync(path)) {
        Directory dir = new Directory(path);
        List<FileSystemEntity> children = dir.listSync(recursive: true);
        Iterable<FileSystemEntity> validTests =
            children.where((FileSystemEntity e) {
          Uri uri = Uri.parse(e.absolute.path);
          return (
              // Is a file, not a directory.
              e is File &&
                  // Is not a package dependency file.
                  !(Uri.parse(e.path).pathSegments.contains('packages')) &&
                  // Is a valid test file.
                  e.path.endsWith(_testFilePattern));
        });
        _files.addAll(validTests);
      }
    });
  }

  /// Generated file with the coverage collection information in JSON format.
  File get collection => _collection;

  /// Completes when the coverage collection, formatting, and optional report
  /// generation has finished. Completes with a [CoverageResult] instance.
  Future<CoverageResult> get done => _done.future;

  /// Combination of the underlying process stderrs, including individual test
  /// runs and the collection of coverage from each, the formatting of the
  /// complete coverage data set, and the generation of an HTML report if
  /// applicable. Each item in the stream is a line.
  Stream<String> get errorOutput => _coverageErrorOutput.stream;

  /// Generated file with the coverage collection information in LCOV format.
  File get lcov => _lcov;

  /// Combination of the underlying process stdouts, including individual test
  /// runs and the collection of coverage from each, the formatting of the
  /// complete coverage data set, and the generation of an HTML report if
  /// applicable. Each item in the stream is a line.
  Stream<String> get output => _coverageOutput.stream;

  /// Directory containing the generated coverage report.
  Directory get report => _outputDirectory;

  /// All test files (expanded from the given list of test paths).
  /// This is the exact list of tests that were run for coverage collection.
  Iterable<String> get tests => _files.map((f) => f.path);

  Future _collect() async {
    List<File> collections = [];
    for (int i = 0; i < _files.length; i++) {
      File collection = new File(path.join(
          _outputDirectory.path, 'collection', '${_files[i].path}.json'));
      int observatoryPort;

      // Run the test and obtain the observatory port for coverage collection.
      try {
        observatoryPort = await _test(_files[i]);
      } on TestException {
        _coverageErrorOutput.add('Tests failed: ${_files[i].path}');
        continue;
      }

      // Collect the coverage from observatory.
      String executable = 'pub';
      List args = [
        'run',
        'coverage:collect_coverage',
        '--port=${observatoryPort}',
        '-o',
        collection.path
      ];

      _coverageOutput.add('');
      _coverageOutput.add('Collecting coverage for ${_files[i].path}');
      _coverageOutput.add('$executable ${args.join(' ')}\n');

      TaskProcess process = new TaskProcess(executable, args);
      process.stdout.listen((l) => _coverageOutput.add('    $l'));
      process.stderr.listen((l) => _coverageErrorOutput.add('    $l'));
      await process.done;
      _killTest();
      if (await process.exitCode > 0) continue;
      collections.add(collection);
    }

    // Merge all individual coverage collection files into one.
    _collection = _merge(collections);
  }

  Future _format(List<String> reportOn) async {
    _lcov = new File(path.join(_outputDirectory.path, 'coverage.lcov'));

    String executable = 'pub';
    List args = [
      'run',
      'coverage:format_coverage',
      '-l',
      '--package-root=packages',
      '-i',
      collection.path,
      '-o',
      lcov.path,
      '--verbose'
    ];
    args.addAll(reportOn.map((p) => '--report-on=$p'));

    _coverageOutput.add('');
    _coverageOutput.add('Formatting coverage');
    _coverageOutput.add('$executable ${args.join(' ')}\n');

    TaskProcess process = new TaskProcess(executable, args);
    process.stdout.listen((l) => _coverageOutput.add('    $l'));
    process.stderr.listen((l) => _coverageErrorOutput.add('    $l'));
    await process.done;

    if (lcov.existsSync()) {
      _coverageOutput.add('');
      _coverageOutput.add('Coverage formatted to LCOV: ${lcov.path}');
    } else {
      String error =
          'Coverage formatting failed. Could not generate ${lcov.path}';
      _coverageErrorOutput.add(error);
      throw new Exception(error);
    }
  }

  Future _generateReport() async {
    String executable = 'genhtml';
    List args = ['-o', _outputDirectory.path, lcov.path];

    _coverageOutput.add('');
    _coverageOutput.add('Generating HTML report...');
    _coverageOutput.add('$executable ${args.join(' ')}\n');

    TaskProcess process = new TaskProcess(executable, args);
    process.stdout.listen((l) => _coverageOutput.add('    $l'));
    process.stderr.listen((l) => _coverageErrorOutput.add('    $l'));
    await process.done;
  }

  void _killTest() {
    _lastTestProcess.kill();
    _lastTestProcess = null;
    if (_lastHtmlFile != null) {
      _lastHtmlFile.deleteSync();
    }
  }

  File _merge(List<File> collections) {
    if (collections.isEmpty) throw new ArgumentError(
        'Cannot merge an empty list of coverages.');

    Map mergedJson = JSON.decode(collections.first.readAsStringSync());
    for (int i = 1; i < collections.length; i++) {
      Map coverageJson = JSON.decode(collections[i].readAsStringSync());
      mergedJson['coverage'].addAll(coverageJson['coverage']);
      collections[i].deleteSync();
    }

    File coverage = new File(path.join(_outputDirectory.path, 'coverage.json'));
    if (coverage.existsSync()) {
      coverage.deleteSync();
    }
    coverage.createSync();
    coverage.writeAsStringSync(JSON.encode(mergedJson));
    return coverage;
  }

  Future<int> _test(File file) async {
    // Look for a correlating HTML file.
    String htmlPath = file.absolute.path;
    htmlPath = htmlPath.substring(0, htmlPath.length - '.dart'.length);
    htmlPath = '$htmlPath.html';
    File customHtmlFile = new File(htmlPath);

    // Build or modify the HTML file to properly load the test.
    File htmlFile;
    if (customHtmlFile.existsSync()) {
      // A custom HTML file exists, but is designed for the test package's
      // test runner. A slightly modified version of that file is needed.
      htmlFile = _lastHtmlFile = new File('${customHtmlFile.path}.temp.html');
      file.createSync();
      String contents = customHtmlFile.readAsStringSync();
      String testFile = file.uri.pathSegments.last;
      var linkP1 =
          new RegExp(r'<link .*rel="x-dart-test" .*href="([\w/]+\.dart)"');
      var linkP2 =
          new RegExp(r'<link .*href="([\w/]+\.dart)" .*rel="x-dart-test"');
      if (linkP1.hasMatch(contents)) {
        Match match = linkP1.firstMatch(contents);
        testFile = match.group(1);
      } else if (linkP2.hasMatch(contents)) {
        Match match = linkP2.firstMatch(contents);
        testFile = match.group(1);
      }

      String dartJsScript = '<script src="packages/test/dart.js"></script>';
      String testScript =
          '<script type="application/dart" src="$testFile"></script>';
      contents = contents.replaceFirst(dartJsScript, testScript);
      htmlFile.writeAsStringSync(contents);
    } else {
      // Create an HTML file that simply loads the test file.
      htmlFile = _lastHtmlFile = new File('${file.path}.temp.html');
      htmlFile.createSync();
      String testFile = file.uri.pathSegments.last;
      htmlFile.writeAsStringSync(
          '<script type="application/dart" src="$testFile"></script>');
    }

    // Determine if this is a VM test or a browser test.
    bool isBrowserTest;
    if (customHtmlFile.existsSync()) {
      isBrowserTest = true;
    } else {
      // Run analysis on file in "Server" category and look for "Library not
      // found" errors, which indicates a `dart:html` import.
      ProcessResult pr = await Process.run(
          'dart2js',
          [
            '--analyze-only',
            '--categories=Server',
            '--package-root=packages',
            file.path
          ],
          runInShell: true);
      // TODO: When dart2js has fixed the issue with their exitcode we should
      //       rely on the exitcode instead of the stdout.
      isBrowserTest = pr.stdout != null &&
          (pr.stdout as String).contains('Error: Library not found');
    }

    String _observatoryFailPattern = 'Could not start Observatory HTTP server';
    RegExp _observatoryPortPattern = new RegExp(
        r'Observatory listening (at|on) http:\/\/127\.0\.0\.1:(\d+)');

    String _testsFailedPattern = 'Some tests failed.';
    String _testsPassedPattern = 'All tests passed!';

    if (isBrowserTest) {
      // Run the test in content-shell.
      String executable = 'content_shell';
      List args = [htmlFile.path];
      _coverageOutput.add('');
      _coverageOutput.add('Running test suite ${file.path}');
      _coverageOutput.add('$executable ${args.join(' ')}\n');
      TaskProcess process =
          _lastTestProcess = new TaskProcess('content_shell', args);

      // Content-shell dumps render tree to stderr, which is where the test
      // results will be. The observatory port should be output to stderr as
      // well, but it is sometimes malformed. In those cases, the correct
      // observatory port is output to stdout. So we listen to both.
      int observatoryPort;
      process.stdout.listen((line) {
        _coverageOutput.add('    $line');
        if (line.contains(_observatoryPortPattern)) {
          Match m = _observatoryPortPattern.firstMatch(line);
          observatoryPort = int.parse(m.group(2));
        }
      });
      await for (String line in process.stderr) {
        _coverageOutput.add('    $line');
        if (line.contains(_observatoryFailPattern)) {
          throw new TestException();
        }
        if (line.contains(_observatoryPortPattern)) {
          Match m = _observatoryPortPattern.firstMatch(line);
          observatoryPort = int.parse(m.group(2));
        }
        if (line.contains(_testsFailedPattern)) {
          throw new TestException();
        }
        if (line.contains(_testsPassedPattern)) {
          break;
        }
      }

      return observatoryPort;
    } else {
      // Find an open port to observe the Dart VM on.
      int port = await getOpenPort();

      // Run the test on the Dart VM.
      String executable = 'dart';
      List args = ['--observe=$port', file.path];
      _coverageOutput.add('');
      _coverageOutput.add('Running test suite ${file.path}');
      _coverageOutput.add('$executable ${args.join(' ')}\n');
      TaskProcess process =
          _lastTestProcess = new TaskProcess(executable, args);
      process.stderr.listen((l) => _coverageErrorOutput.add('    $l'));

      await for (String line in process.stdout) {
        _coverageOutput.add('    $line');
        if (line.contains(_observatoryFailPattern)) {
          throw new TestException();
        }
        if (line.contains(_testsFailedPattern)) {
          throw new TestException();
        }
        if (line.contains(_testsPassedPattern)) {
          break;
        }
      }

      return port;
    }
  }
}

class TestException implements Exception {}
