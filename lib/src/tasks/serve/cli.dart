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

library dart_dev.src.tasks.serve.cli;

import 'dart:async';

import 'package:args/args.dart';

import 'package:dart_dev/util.dart' show reporter;

import 'package:dart_dev/src/tasks/serve/api.dart';
import 'package:dart_dev/src/tasks/serve/config.dart';
import 'package:dart_dev/src/tasks/cli.dart';
import 'package:dart_dev/src/tasks/config.dart';

class ServeCli extends TaskCli {
  final ArgParser argParser = new ArgParser()
    ..addOption('hostname',
  defaultsTo: defaultHostname, help: 'The host name to listen on.')
    ..addOption('port',
  defaultsTo: defaultPort.toString(),
  help: 'The base port to listen on.');

  final String command = 'serve';

  Future<CliResult> run(ArgResults parsedArgs) async {
    String hostname =
    TaskCli.valueOf('hostname', parsedArgs, config.serve.hostname);
    var port = TaskCli.valueOf('port', parsedArgs, config.serve.port);
    if (port is String) {
      port = int.parse(port);
    }

    ExamplesTask task = startPubServe(hostname: hostname, port: port);
    reporter.logGroup(task.pubServeCommand, outputStream: task.pubServeOutput);
    await task.done;
    return task.successful ? new CliResult.success() : new CliResult.fail();
  }
}
