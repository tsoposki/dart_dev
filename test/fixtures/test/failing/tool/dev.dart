library tool.dev;

import 'package:dart_dev/dart_dev.dart' show dev, config;

main(List<String> args) async {
  config.test
    ..unitTests = ['test/failing_unit_test.dart']
    ..integrationTests = ['test/failing_integration_test.dart'];

  await dev(args);
}
