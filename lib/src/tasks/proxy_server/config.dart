library dart_dev.src.tasks.proxy_server.config;

import 'package:dart_dev/src/tasks/config.dart';

const String PROXY_SERVER_PATH = 'bin/server.dart';
const String PUB_SERVER_HOSTNAME = 'pubServerHostname';
const String PUB_SERVER_PORT = 'pubServerPort';
const String API_URL = 'apiUrl';
const String API_PORT = 'apiPort';
const String API_CONTEXT = 'apiContext';
const String PROXY_SERVER_HOSTNAME = 'proxyServerHostname';
const String PROXY_SERVER_PORT = 'proxyServerPort';

const String defaultPubServerHostname = 'localhost';
const int defaultPubServerPort = 9152;
const String defaultApiUrl = 'http://www.example.com/api';
const int defaultApiPort = 80;
const String defaultApiContext = '/api';
const String defaultProxyServerHostname = 'localhost';
const int defaultProxyServerPort = 9162;

class ProxyServerConfig extends TaskConfig {
  String pubServerHostname = defaultPubServerHostname;
  int pubServerPort = defaultPubServerPort;
  String apiUrl = defaultApiUrl;
  int apiPort = defaultApiPort;
  String apiContext = defaultApiContext;
  String proxyServerHostname = defaultProxyServerHostname;
  int proxyServerPort = defaultProxyServerPort;
}
