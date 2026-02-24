import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/project_info.dart';

class GradleScanner {
  AndroidInfo scan(String projectPath) {
    final androidDir = Directory(p.join(projectPath, 'android'));
    if (!androidDir.existsSync()) {
      return const AndroidInfo(found: false);
    }

    return AndroidInfo(
      found: true,
      compileSdk: _extractCompileSdk(projectPath),
      minSdk: _extractMinSdk(projectPath),
      targetSdk: _extractTargetSdk(projectPath),
      agpVersion: _extractAgpVersion(projectPath),
      kotlinVersion: _extractKotlinVersion(projectPath),
      gradleVersion: _extractGradleVersion(projectPath),
      javaVersion: _extractJavaVersion(projectPath),
      ndkVersion: _extractNdkVersion(projectPath),
    );
  }

  int? _extractCompileSdk(String projectPath) {
    final content = _readAppBuildGradle(projectPath);
    if (content == null) return null;
    return _extractInt(content, [
      RegExp(r'compileSdk\s*[=]?\s*(\d+)'),
      RegExp(r'compileSdkVersion\s+(\d+)'),
    ]);
  }

  int? _extractMinSdk(String projectPath) {
    final localProps = _readFile(projectPath, 'android/local.properties');
    if (localProps != null) {
      final match = RegExp(
        r'flutter\.minSdkVersion\s*=\s*(\d+)',
      ).firstMatch(localProps);
      if (match != null) return int.tryParse(match.group(1)!);
    }

    final content = _readAppBuildGradle(projectPath);
    if (content == null) return null;
    return _extractInt(content, [
      RegExp(r'minSdk\s*[=]?\s*(\d+)'),
      RegExp(r'minSdkVersion\s+(\d+)'),
      RegExp(r'minSdk\s*=?\s*flutter\.minSdkVersion'),
    ]);
  }

  int? _extractTargetSdk(String projectPath) {
    final content = _readAppBuildGradle(projectPath);
    if (content == null) return null;
    return _extractInt(content, [
      RegExp(r'targetSdk\s*[=]?\s*(\d+)'),
      RegExp(r'targetSdkVersion\s+(\d+)'),
    ]);
  }

  String? _extractAgpVersion(String projectPath) {
    final settingsContent = _readFile(projectPath, 'android/settings.gradle');
    if (settingsContent != null) {
      final match = RegExp(
        r'id\s+"com\.android\.\w+"\s+version\s+"([^"]+)"',
      ).firstMatch(settingsContent);
      if (match != null) return match.group(1);
    }

    final settingsKtsContent = _readFile(
      projectPath,
      'android/settings.gradle.kts',
    );
    if (settingsKtsContent != null) {
      final match = RegExp(
        r'id\("com\.android\.\w+"\)\s+version\s+"([^"]+)"',
      ).firstMatch(settingsKtsContent);
      if (match != null) return match.group(1);
    }

    final content = _readFile(projectPath, 'android/build.gradle');
    if (content != null) {
      final match = RegExp(
        r'''classpath\s+['"]com\.android\.tools\.build:gradle:([^'"]+)['"]''',
      ).firstMatch(content);
      if (match != null) return match.group(1);
    }

    return null;
  }

  String? _extractKotlinVersion(String projectPath) {
    final settingsContent = _readFile(projectPath, 'android/settings.gradle');
    if (settingsContent != null) {
      final match = RegExp(
        r'id\s+"org\.jetbrains\.kotlin\.\w+"\s+version\s+"([^"]+)"',
      ).firstMatch(settingsContent);
      if (match != null) return match.group(1);
    }

    final settingsKtsContent = _readFile(
      projectPath,
      'android/settings.gradle.kts',
    );
    if (settingsKtsContent != null) {
      final match = RegExp(
        r'id\("org\.jetbrains\.kotlin\.\w+"\)\s+version\s+"([^"]+)"',
      ).firstMatch(settingsKtsContent);
      if (match != null) return match.group(1);
    }

    final content = _readFile(projectPath, 'android/build.gradle');
    if (content != null) {
      var match = RegExp(
        r'''ext\.kotlin_version\s*=\s*['"]([^'"]+)['"]''',
      ).firstMatch(content);
      if (match != null) return match.group(1);

      match = RegExp(
        r'''classpath\s+['"]org\.jetbrains\.kotlin:kotlin-gradle-plugin:([^'"]+)['"]''',
      ).firstMatch(content);
      if (match != null) return match.group(1);
    }

    return null;
  }

  String? _extractGradleVersion(String projectPath) {
    final content = _readFile(
      projectPath,
      'android/gradle/wrapper/gradle-wrapper.properties',
    );
    if (content == null) return null;

    final match = RegExp(
      r'distributionUrl.*gradle-(\d+\.\d+(?:\.\d+)?)-',
    ).firstMatch(content);
    return match?.group(1);
  }

  String? _extractJavaVersion(String projectPath) {
    final content = _readAppBuildGradle(projectPath);
    if (content == null) return null;

    final match = RegExp(r'JavaVersion\.VERSION_(\d+)').firstMatch(content);
    return match?.group(1);
  }

  String? _extractNdkVersion(String projectPath) {
    final content = _readAppBuildGradle(projectPath);
    if (content == null) return null;

    final match = RegExp(
      r'''ndkVersion\s+['"]([^'"]+)['"]''',
    ).firstMatch(content);
    return match?.group(1);
  }


  String? _readAppBuildGradle(String projectPath) {
    return _readFile(projectPath, 'android/app/build.gradle') ??
        _readFile(projectPath, 'android/app/build.gradle.kts');
  }

  String? _readFile(String projectPath, String relativePath) {
    final file = File(p.join(projectPath, relativePath));
    if (!file.existsSync()) return null;
    return file.readAsStringSync();
  }

  int? _extractInt(String content, List<RegExp> patterns) {
    for (final pattern in patterns) {
      final match = pattern.firstMatch(content);
      if (match != null && match.groupCount >= 1) {
        return int.tryParse(match.group(1)!);
      }
    }
    return null;
  }
}
