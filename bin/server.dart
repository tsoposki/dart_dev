import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_proxy/shelf_proxy.dart';
import 'package:shelf_route/shelf_route.dart';
import 'package:args/args.dart';
import 'package:dart_dev/src/tasks/proxy_server/config.dart';


ArgResults argResults;

void main(List<String> args) {
  final parser = new ArgParser()
    ..addOption(PUB_SERVER_HOSTNAME)
    ..addOption(PUB_SERVER_PORT)
    ..addOption(API_URL)
    ..addOption(API_CONTEXT)
    ..addOption(API_PORT)
    ..addOption(PROXY_SERVER_HOSTNAME)
    ..addOption(PROXY_SERVER_PORT);

  var results = parser.parse(args);

  var myRouter = router()
    ..add(results['$API_CONTEXT'], null, proxyHandler(results['$API_URL'] + ":" + results['$API_PORT']), exactMatch: false)
    ..add('/', null, proxyHandler(results['$PUB_SERVER_HOSTNAME'] + ":" + results['$PUB_SERVER_PORT']));

  io.serve(myRouter.handler, results['$PROXY_SERVER_HOSTNAME'], 8080);
}