import 'dart:io';

import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as p;

import '../models/project_info.dart';

class PubspecScanner {
  PubspecInfo scanPubspec(String projectPath) {
    final pubspecFile = File(p.join(projectPath, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) {
      throw FileSystemException('pubspec.yaml not found', pubspecFile.path);
    }

    final content = pubspecFile.readAsStringSync();
    final yaml = loadYaml(content) as YamlMap;

    final environment = yaml['environment'] as YamlMap?;
    final deps = yaml['dependencies'] as YamlMap?;
    final devDeps = yaml['dev_dependencies'] as YamlMap?;
    final overrides = yaml['dependency_overrides'] as YamlMap?;

    return PubspecInfo(
      sdkConstraint: environment?['sdk']?.toString(),
      flutterConstraint: environment?['flutter']?.toString(),
      dependencies: _yamlMapToMap(deps),
      devDependencies: _yamlMapToMap(devDeps),
      dependencyOverrides: _yamlMapToMap(overrides),
    );
  }

  LockfileInfo scanLockfile(String projectPath) {
    final lockFile = File(p.join(projectPath, 'pubspec.lock'));
    if (!lockFile.existsSync()) {
      return const LockfileInfo(packages: {});
    }

    final content = lockFile.readAsStringSync();
    final yaml = loadYaml(content) as YamlMap;
    final packages = <String, LockedPackage>{};

    final packagesMap = yaml['packages'] as YamlMap?;
    if (packagesMap != null) {
      for (final entry in packagesMap.entries) {
        final name = entry.key.toString();
        final data = entry.value as YamlMap;
        packages[name] = LockedPackage(
          name: name,
          version: data['version']?.toString() ?? 'unknown',
          source: data['source']?.toString() ?? 'unknown',
        );
      }
    }

    return LockfileInfo(packages: packages);
  }

  String getProjectName(String projectPath) {
    final pubspecFile = File(p.join(projectPath, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) return p.basename(projectPath);

    final content = pubspecFile.readAsStringSync();
    final yaml = loadYaml(content) as YamlMap;
    return yaml['name']?.toString() ?? p.basename(projectPath);
  }

  Map<String, dynamic> _yamlMapToMap(YamlMap? yamlMap) {
    if (yamlMap == null) return {};
    final result = <String, dynamic>{};
    for (final entry in yamlMap.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      if (value is YamlMap) {
        result[key] = _yamlMapToMap(value);
      } else if (value is YamlList) {
        result[key] = value.toList();
      } else {
        result[key] = value;
      }
    }
    return result;
  }
}
