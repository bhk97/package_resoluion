import 'package:pub_semver/pub_semver.dart';

import '../models/conflict.dart';
import '../models/package_info.dart';
import '../models/project_info.dart';

class DartChecker {
  List<Conflict> check(ProjectInfo project, PackageVersion packageVersion) {
    final conflicts = <Conflict>[];

    _checkSdkConstraint(project, packageVersion, conflicts);

    _checkFlutterConstraint(project, packageVersion, conflicts);

    _checkDirectDependencyConflicts(project, packageVersion, conflicts);

    _checkTransitiveDependencyConflicts(project, packageVersion, conflicts);

    return conflicts;
  }

  void _checkSdkConstraint(
    ProjectInfo project,
    PackageVersion packageVersion,
    List<Conflict> conflicts,
  ) {
    if (packageVersion.sdkConstraint == null ||
        project.pubspec.sdkConstraint == null) {
      return;
    }

    try {
      final projectSdk = VersionConstraint.parse(
        project.pubspec.sdkConstraint!,
      );
      final packageSdk = VersionConstraint.parse(packageVersion.sdkConstraint!);

      if (!_hasOverlap(projectSdk, packageSdk)) {
        conflicts.add(
          Conflict(
            layer: ConflictLayer.dart,
            severity: ConflictSeverity.error,
            title: 'Dart SDK constraint mismatch',
            description: 'Package requires sdk ${packageVersion.sdkConstraint} '
                'but your project specifies sdk ${project.pubspec.sdkConstraint}',
            filePath: 'pubspec.yaml',
            fixes: [
              Fix(
                filePath: 'pubspec.yaml',
                description: 'Update SDK constraint in environment section',
                currentValue: 'sdk: ${project.pubspec.sdkConstraint}',
                recommendedValue: 'sdk: ${packageVersion.sdkConstraint}',
              ),
            ],
          ),
        );
      }
    } catch (_) {}
  }

  void _checkFlutterConstraint(
    ProjectInfo project,
    PackageVersion packageVersion,
    List<Conflict> conflicts,
  ) {
    if (packageVersion.flutterConstraint == null) return;

    if (project.flutterSdk.flutterVersion != 'unknown') {
      try {
        final installedVersion = Version.parse(
          project.flutterSdk.flutterVersion,
        );
        final packageFlutterConstraint = VersionConstraint.parse(
          packageVersion.flutterConstraint!,
        );

        if (!packageFlutterConstraint.allows(installedVersion)) {
          conflicts.add(
            Conflict(
              layer: ConflictLayer.dart,
              severity: ConflictSeverity.error,
              title: 'Flutter SDK version incompatible',
              description:
                  'Package requires Flutter ${packageVersion.flutterConstraint} '
                  'but you have Flutter ${project.flutterSdk.flutterVersion} installed',
              fixes: [
                Fix(
                  filePath: 'Flutter SDK',
                  description: 'Upgrade Flutter SDK',
                  currentValue: project.flutterSdk.flutterVersion,
                  recommendedValue:
                      'Run: flutter upgrade (needs ${packageVersion.flutterConstraint})',
                ),
              ],
            ),
          );
        }
      } catch (_) {}
    }
  }

  void _checkDirectDependencyConflicts(
    ProjectInfo project,
    PackageVersion packageVersion,
    List<Conflict> conflicts,
  ) {
    for (final entry in packageVersion.dependencies.entries) {
      final depName = entry.key;
      final newConstraintStr = entry.value?.toString();
      if (newConstraintStr == null) continue;

      final projectConstraint = project.pubspec.dependencies[depName];
      if (projectConstraint == null) continue;
      if (projectConstraint is! String) continue;

      try {
        final newConstraint = VersionConstraint.parse(newConstraintStr);
        final existingConstraint = VersionConstraint.parse(projectConstraint);

        if (!_hasOverlap(newConstraint, existingConstraint)) {
          final suggestedVersion = _suggestOverlappingConstraint(
            depName,
            existingConstraint,
            newConstraint,
          );

          conflicts.add(
            Conflict(
              layer: ConflictLayer.dart,
              severity: ConflictSeverity.error,
              title: 'Dependency conflict: $depName',
              description: 'Package needs $depName $newConstraintStr '
                  'but your project requires $depName $projectConstraint',
              filePath: 'pubspec.yaml',
              fixes: [
                Fix(
                  filePath: 'pubspec.yaml',
                  description: 'Update $depName constraint',
                  currentValue: '$depName: $projectConstraint',
                  recommendedValue: suggestedVersion != null
                      ? '$depName: $suggestedVersion'
                      : '$depName: $newConstraintStr (breaking change — review carefully)',
                ),
              ],
            ),
          );
        }
      } catch (_) {}
    }
  }

  void _checkTransitiveDependencyConflicts(
    ProjectInfo project,
    PackageVersion packageVersion,
    List<Conflict> conflicts,
  ) {
    for (final entry in packageVersion.dependencies.entries) {
      final depName = entry.key;
      final newConstraintStr = entry.value?.toString();
      if (newConstraintStr == null) continue;

      final locked = project.lockfile.packages[depName];
      if (locked == null) continue;

      try {
        final newConstraint = VersionConstraint.parse(newConstraintStr);
        final lockedVersion = Version.parse(locked.version);

        if (!newConstraint.allows(lockedVersion)) {
          conflicts.add(
            Conflict(
              layer: ConflictLayer.dart,
              severity: ConflictSeverity.warning,
              title: 'Transitive dependency conflict: $depName',
              description: 'Package needs $depName $newConstraintStr '
                  'but $depName ${locked.version} is currently locked. '
                  'Running `flutter pub get` may resolve this automatically.',
              filePath: 'pubspec.lock',
              fixes: [
                Fix(
                  filePath: 'pubspec.lock',
                  description:
                      'Will be updated automatically by `flutter pub get`',
                  currentValue: '$depName: ${locked.version}',
                  recommendedValue: '$depName: (needs $newConstraintStr)',
                ),
              ],
            ),
          );
        }
      } catch (_) {}
    }
  }

  bool _hasOverlap(VersionConstraint a, VersionConstraint b) {
    if (a.isAny || b.isAny) return true;
    if (a.isEmpty || b.isEmpty) return false;

    return a.intersect(b) != VersionConstraint.empty;
  }

  String? _suggestOverlappingConstraint(
    String packageName,
    VersionConstraint existing,
    VersionConstraint required,
  ) {
    final intersection = existing.intersect(required);
    if (intersection != VersionConstraint.empty) {
      return intersection.toString();
    }
    return null;
  }
}
