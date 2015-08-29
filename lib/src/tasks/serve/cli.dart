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
