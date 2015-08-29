import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_proxy/shelf_proxy.dart';
import 'package:shelf_route/shelf_route.dart';
import 'package:args/args.dart';
import 'package:dart_dev/src/tasks/proxy_server/config.dart';


ArgResults argResults;

void main(List<String> args) {
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

  var results = argParser.parse(args);

  var proxyServerPort = results['$PROXY_SERVER_PORT'];
  if (proxyServerPort is String) {
    proxyServerPort = int.parse(proxyServerPort);
  }

  var myRouter = router()
    ..add(results['$API_CONTEXT'], null, proxyHandler(results['$API_URL'] + ":" + results['$API_PORT']), exactMatch: false)
    ..add('/', null, proxyHandler(results['$PUB_SERVER_HOSTNAME'] + ":" + results['$PUB_SERVER_PORT']));

  io.serve(myRouter.handler, results['$PROXY_SERVER_HOSTNAME'], proxyServerPort);
}