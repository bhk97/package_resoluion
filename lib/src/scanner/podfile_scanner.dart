import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/project_info.dart';

class PodfileScanner {
  IosInfo scan(String projectPath) {
    final iosDir = Directory(p.join(projectPath, 'ios'));
    if (!iosDir.existsSync()) {
      return const IosInfo(found: false);
    }

    final podfile = File(p.join(projectPath, 'ios', 'Podfile'));
    if (!podfile.existsSync()) {
      return const IosInfo(found: true);
    }

    final content = podfile.readAsStringSync();

    return IosInfo(
      found: true,
      deploymentTarget: _extractDeploymentTarget(content),
      useFrameworks: _extractUseFrameworks(content),
    );
  }

  String? _extractDeploymentTarget(String content) {
    final match = RegExp(
      r'''platform\s+:ios\s*,\s*['"](\d+\.\d+)['"]''',
    ).firstMatch(content);
    return match?.group(1);
  }

  bool? _extractUseFrameworks(String content) {
    if (content.contains('use_frameworks!')) {
      return true;
    }
    if (content.contains('use_modular_headers!')) {
      return false;
    }
    return null;
  }
}
