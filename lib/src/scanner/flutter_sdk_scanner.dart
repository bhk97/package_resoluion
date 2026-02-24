import 'dart:io';

import '../models/project_info.dart';

class FlutterSdkScanner {
  Future<FlutterSdkInfo> scan() async {
    try {
      final result = await Process.run('flutter', ['--version']);
      if (result.exitCode != 0) {
        return _fallback();
      }

      final output = result.stdout.toString();
      return FlutterSdkInfo(
        flutterVersion: _extractFlutterVersion(output) ?? 'unknown',
        dartVersion: _extractDartVersion(output) ?? 'unknown',
        channel: _extractChannel(output) ?? 'unknown',
      );
    } catch (e) {
      return _fallback();
    }
  }

  String? _extractFlutterVersion(String output) {
    final match = RegExp(r'Flutter\s+(\d+\.\d+\.\d+)').firstMatch(output);
    return match?.group(1);
  }

  String? _extractDartVersion(String output) {
    var match = RegExp(
      r'Dart\s+(?:SDK\s+)?version:?\s*(\d+\.\d+\.\d+)',
    ).firstMatch(output);
    if (match != null) return match.group(1);

    match = RegExp(r'Dart\s+version\s+(\d+\.\d+\.\d+)').firstMatch(output);
    return match?.group(1);
  }

  String? _extractChannel(String output) {
    final match = RegExp(r'channel\s+(\w+)').firstMatch(output);
    return match?.group(1);
  }

  FlutterSdkInfo _fallback() {
    return const FlutterSdkInfo(
      flutterVersion: 'unknown',
      dartVersion: 'unknown',
      channel: 'unknown',
    );
  }
}
