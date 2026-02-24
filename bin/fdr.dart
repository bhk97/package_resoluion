import 'dart:io';

import 'package:fdr/src/cli/runner.dart';

void main(List<String> args) async {
  final runner = CliRunner();
  final exitCode = await runner.run(args);
  exit(exitCode);
}
