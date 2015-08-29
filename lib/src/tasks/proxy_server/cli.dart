library dart_dev.src.tasks.proxy_server.cli;

import 'dart:async';

import 'package:args/args.dart';

import 'package:dart_dev/util.dart' show reporter;

import 'package:dart_dev/src/tasks/proxy_server/api.dart';
import 'package:dart_dev/src/tasks/proxy_server/config.dart';
import 'package:dart_dev/src/tasks/cli.dart';
import 'package:dart_dev/src/tasks/config.dart';

class ProxyServerCli extends TaskCli {
  final ArgParser argParser = new ArgParser()
    ..addOption(PUB_SERVER_HOSTNAME,
  defaultsTo: defaultPubServerHostname,
  help: 'The pub server host name.')
    ..addOption(PUB_SERVER_PORT,
  defaultsTo: defaultPubServerPort.toString(),
  help: 'The pub server port.')
    ..addOption(API_URL,
  defaultsTo: defaultApiUrl,
  help: 'The API endpoint.')
    ..addOption(API_PORT,
  defaultsTo: defaultApiPort.toString(),
  help: 'The port of API endpoint.')
    ..addOption(API_CONTEXT,
  defaultsTo: defaultApiContext,
  help: 'The API context.')
    ..addOption(PROXY_SERVER_HOSTNAME,
  defaultsTo: defaultProxyServerHostname,
  help: 'The proxy server host name.')
    ..addOption(PROXY_SERVER_PORT,
  defaultsTo: defaultProxyServerPort.toString(),
  help: 'The proxy server port.');

  final String command = 'proxy-server';

  Future<CliResult> run(ArgResults parsedArgs) async {
    String pubServerHostname = TaskCli.valueOf(PUB_SERVER_HOSTNAME, parsedArgs, config.proxyServer.pubServerHostname);
    var pubServerPort = TaskCli.valueOf(PUB_SERVER_PORT, parsedArgs, config.proxyServer.pubServerPort);
    if (pubServerPort is String) {
      pubServerPort = int.parse(pubServerPort);
    }
    String apiUrl = TaskCli.valueOf(API_URL, parsedArgs, config.proxyServer.apiUrl);
    var apiPort = TaskCli.valueOf(API_PORT, parsedArgs, config.proxyServer.apiPort);
    if (apiPort is String) {
      apiPort = int.parse(apiPort);
    }
    String apiContext = TaskCli.valueOf(API_CONTEXT, parsedArgs, config.proxyServer.apiContext);
    String proxyServerHostname = TaskCli.valueOf(PROXY_SERVER_HOSTNAME, parsedArgs, config.proxyServer.proxyServerHostname);
    var proxyServerPort = TaskCli.valueOf(PROXY_SERVER_PORT, parsedArgs, config.proxyServer.proxyServerPort);
    if (proxyServerPort is String) {
      proxyServerPort = int.parse(proxyServerPort);
    }

    ProxyServerTask task = startProxyServer(
        pubServerHostname: pubServerHostname,
        pubServerPort: pubServerPort,
        apiUrl: apiUrl,
        apiPort: apiPort,
        apiContext: apiContext,
        proxyServerHostname: proxyServerHostname,
        proxyServerPort: proxyServerPort
    );

//    reporter.logGroup(task.pubServeCommand, outputStream: task.pubServeOutput);
    await task.done;
    reporter.logGroup(task.dartiumCommand, outputStream: task.dartiumOutput);
    return task.successful ? new CliResult.success() : new CliResult.fail();
  }
}
