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

library dart_dev.src.tasks.serve.api;

import 'dart:async';
import 'dart:io';

import 'package:dart_dev/util.dart' show TaskProcess;

import 'package:dart_dev/src/tasks/serve/config.dart';
import 'package:dart_dev/src/tasks/task.dart';

ServeTask serve({List<String> directories,
    String hostname: defaultHostname, int port: defaultPort}) {
  if (directories != null) {
    List<String> nonexistent = directories.where((p) => !(new Directory(p).existsSync()));
    if (nonexistent.isNotEmpty) throw new Exception('These directories do not exist: ${nonexistent.join(', ')}');
  }

  var dartiumExecutable = 'dartium';
  var dartiumArgs = ['http://$hostname:$port'];

  var pubServeExecutable = 'pub';
  var pubServeArgs = [
    'serve',
    '--hostname=$hostname',
    '--port=$port'
  ];
  if (directories != null) {
    pubServeArgs.addAll(directories);
  }

  TaskProcess pubServeProcess =
      new TaskProcess(pubServeExecutable, pubServeArgs);
  TaskProcess dartiumProcess = new TaskProcess(dartiumExecutable, dartiumArgs);

  ServeTask task = new ServeTask(
      '$dartiumExecutable ${dartiumArgs.join(' ')}',
      '$pubServeExecutable ${pubServeArgs.join(' ')}',
      Future.wait([dartiumProcess.done, pubServeProcess.done]));

  pubServeProcess.stdout.listen(task._pubServeOutput.add);
  pubServeProcess.stderr.listen(task._pubServeOutput.addError);
  pubServeProcess.exitCode.then((code) {
    task.successful = code <= 0;
  });

  dartiumProcess.stdout.listen(task._dartiumOutput.add);
  dartiumProcess.stderr.listen(task._dartiumOutput.addError);

  return task;
}

class ServeTask extends Task {
  final Future done;
  final String dartiumCommand;
  final String pubServeCommand;

  StreamController<String> _dartiumOutput = new StreamController();
  StreamController<String> _pubServeOutput = new StreamController();

  ServeTask(String this.dartiumCommand, String this.pubServeCommand,
      Future this.done) {
    done.then((_) {
      _dartiumOutput.close();
      _pubServeOutput.close();
    });
  }

  Stream<String> get dartiumOutput => _dartiumOutput.stream;
  Stream<String> get pubServeOutput => _pubServeOutput.stream;
}
