library dart_dev.src.tasks.serve.config;

import 'package:dart_dev/src/tasks/config.dart';

const String defaultHostname = 'localhost';
const int defaultPort = 9152;

class ServeConfig extends TaskConfig {
  String hostname = defaultHostname;
  int port = defaultPort;
}