library dart_dev.src.tasks.examples.api;

import 'dart:async';

import 'package:dart_dev/util.dart' show TaskProcess;
import 'package:dart_dev/src/tasks/serve/config.dart';
import 'package:dart_dev/src/tasks/task.dart';
import 'package:dart_dev/src/tasks/config.dart';

ExamplesTask startPubServe(
    {String hostname: defaultHostname, int port: defaultPort}) {

  var pubServeExecutable = 'pub';
  var pubServeArgs = [
    'serve',
    '--hostname=$hostname',
    '--port=$port'
  ];

  var dartiumExecutable = 'chrome';
  var dartiumArgs = [
    'http://:' + config.proxyServer.proxyServerHostname + ':' + config.proxyServer.proxyServerPort.toString(),
    '--checked'
  ];


  print('SERVE AT http://:' + config.proxyServer.proxyServerHostname + ':' + config.proxyServer.proxyServerPort.toString());

  TaskProcess pubServeProcess = new TaskProcess(pubServeExecutable, pubServeArgs);

  ExamplesTask task = new ExamplesTask(
      '$pubServeExecutable ${pubServeArgs.join(' ')}',
      Future.wait([
        pubServeProcess.done
      ]));

  pubServeProcess.stdout.listen(task._pubServeOutput.add);
  pubServeProcess.stderr.listen((_err) {
    print('$_err');
  });

  pubServeProcess.exitCode.then((code) {
    task.successful = code <= 0;
  });

  return task;
}

class ExamplesTask extends Task {
  final Future done;
  final String pubServeCommand;

  StreamController<String> _pubServeOutput = new StreamController();

  ExamplesTask(String this.pubServeCommand, Future this.done) {
    done.then((_) {
      _pubServeOutput.close();
    });
  }

  Stream<String> get pubServeOutput => _pubServeOutput.stream;
}
