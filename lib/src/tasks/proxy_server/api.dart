library dart_dev.src.tasks.proxy.api;

import 'dart:async';
import 'package:dart_dev/util.dart' show TaskProcess;
import 'package:dart_dev/src/tasks/proxy_server/config.dart';
import 'package:dart_dev/src/tasks/task.dart';

ProxyServerTask startProxyServer(
    {
      String pubServerHostname: defaultPubServerHostname,
      int pubServerPort: defaultPubServerPort,
      String apiUrl: defaultApiUrl,
      int apiPort: defaultApiPort,
      String apiContext: defaultApiContext,
      String proxyServerHostname: defaultProxyServerHostname,
      int proxyServerPort: defaultProxyServerPort
    }) {

  var dartExecutable = 'dart';
  var proxyServerArgs = [
    '$PROXY_SERVER_PATH',
    '--$PUB_SERVER_HOSTNAME=$pubServerHostname',
    '--$PUB_SERVER_PORT=$pubServerPort',
    '--$API_URL=$apiUrl',
    '--$API_PORT=$apiPort',
    '--$API_CONTEXT=$apiContext',
    '--$PROXY_SERVER_HOSTNAME=$proxyServerHostname',
    '--$PROXY_SERVER_PORT=$proxyServerPort'
  ];

//  var dartiumExecutable = 'chrome';
//  var dartiumArgs = [
//    'http://$proxyServerHostname:$proxyServerPort',
//    '--checked'
//  ];

//  var pubServeExecutable = 'pub';
//  var pubServeArgs = [
//    'serve',
//    '--hostname=$pubServerHostname',
//    '--port=$pubServerPort'
//  ];

  TaskProcess proxyServerProcess = new TaskProcess(dartExecutable, proxyServerArgs);
//  TaskProcess dartiumProcess = new TaskProcess(dartiumExecutable, dartiumArgs);
//  TaskProcess pubServeProcess = new TaskProcess(pubServeExecutable, pubServeArgs);

  ProxyServerTask task = new ProxyServerTask(
      '$dartExecutable ${proxyServerArgs.join(' ')}',
//      '$dartiumExecutable ${dartiumArgs.join(' ')}',
//      '$pubServeExecutable ${pubServeArgs.join(' ')}',
      Future.wait([
        proxyServerProcess.done
//        dartiumProcess.done
//        pubServeProcess.done
      ]));

//  pubServeProcess.stdout.listen(task._pubServeOutput.add);
//  pubServeProcess.stderr.listen(task._pubServeOutput.addError);
//  pubServeProcess.exitCode.then((code) {
//    task.successful = code <= 0;
//  });

//  dartiumProcess.stdout.listen(task._dartiumOutput.add);
//  dartiumProcess.stderr.listen(task._dartiumOutput.addError);

  proxyServerProcess.stdout.listen(task._proxyServerOutput.add);
  proxyServerProcess.stderr.listen((_err) {
    print(_err);
//    task._proxyServerOutput.addError;
  });

  proxyServerProcess.exitCode.then((code) {
    task.successful = code <= 0;
  });

  return task;
}

class ProxyServerTask extends Task {
  final Future done;
  final String dartCommand;
//  final String dartiumCommand;

//  final String pubServeCommand;

  StreamController<String> _proxyServerOutput = new StreamController();
//  StreamController<String> _dartiumOutput = new StreamController();

//  StreamController<String> _pubServeOutput = new StreamController();

  ProxyServerTask(String this.dartCommand,
//                  String this.dartiumCommand,
                  //                  String this.pubServeCommand,
                  Future this.done) {
    done.then((_) {
      _proxyServerOutput.close();
//      _dartiumOutput.close();
//      _pubServeOutput.close();
    });
  }

  Stream<String> get proxyServerOutput => _proxyServerOutput.stream;

//  Stream<String> get dartiumOutput => _dartiumOutput.stream;

//  Stream<String> get pubServeOutput => _pubServeOutput.stream;
}
