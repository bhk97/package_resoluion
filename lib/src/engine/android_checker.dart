import 'package:pub_semver/pub_semver.dart';

import '../models/conflict.dart';
import '../models/package_info.dart';
import '../models/project_info.dart';
import 'compatibility_matrix.dart';

class AndroidChecker {
  List<Conflict> check(ProjectInfo project, PackageVersion packageVersion) {
    final conflicts = <Conflict>[];

    if (!project.android.found) {
      return conflicts;
    }

    if (!packageVersion.platforms.contains('android') &&
        packageVersion.platforms.isNotEmpty) {
      return conflicts;
    }

    _checkCompileSdk(project, packageVersion, conflicts);

    _checkMinSdk(project, packageVersion, conflicts);

    _checkKotlinVersion(project, packageVersion, conflicts);

    _checkAgpChain(project, conflicts);

    return conflicts;
  }

  void _checkCompileSdk(
    ProjectInfo project,
    PackageVersion packageVersion,
    List<Conflict> conflicts,
  ) {
    final compileSdk = project.android.compileSdk;
    if (compileSdk == null) return;

    int? requiredCompileSdk;
    if (packageVersion.sdkConstraint != null) {
      try {
        final constraint = VersionConstraint.parse(
          packageVersion.sdkConstraint!,
        );
        if (constraint is VersionRange && constraint.min != null) {
          if (constraint.min! >= Version(3, 6, 0)) {
            requiredCompileSdk = 35;
          } else if (constraint.min! >= Version(3, 2, 0)) {
            requiredCompileSdk = 34;
          } else if (constraint.min! >= Version(2, 18, 0)) {
            requiredCompileSdk = 33;
          }
        }
      } catch (_) {}
    }

    if (requiredCompileSdk != null && compileSdk < requiredCompileSdk) {
      final minAgp = CompatibilityMatrix.minAgpForCompileSdk(
        requiredCompileSdk,
      );

      final fixes = <Fix>[
        Fix(
          filePath: 'android/app/build.gradle',
          description: 'Increase compileSdk',
          currentValue: 'compileSdk $compileSdk',
          recommendedValue: 'compileSdk $requiredCompileSdk',
        ),
      ];

      if (minAgp != null && project.android.agpVersion != null) {
        try {
          final currentAgp = Version.parse(project.android.agpVersion!);
          final requiredAgp = Version.parse('$minAgp.0');
          if (currentAgp < requiredAgp) {
            final minGradle = CompatibilityMatrix.minGradleForAgp(minAgp);
            fixes.add(
              Fix(
                filePath: 'android/build.gradle or android/settings.gradle',
                description:
                    'Update AGP version (required for compileSdk $requiredCompileSdk)',
                currentValue: 'AGP ${project.android.agpVersion}',
                recommendedValue: 'AGP $minAgp+',
              ),
            );
            if (minGradle != null) {
              fixes.add(
                Fix(
                  filePath: 'android/gradle/wrapper/gradle-wrapper.properties',
                  description:
                      'Update Gradle version (required for AGP $minAgp+)',
                  currentValue:
                      'Gradle ${project.android.gradleVersion ?? "unknown"}',
                  recommendedValue: 'Gradle $minGradle+',
                ),
              );
            }
          }
        } catch (_) {}
      }

      conflicts.add(
        Conflict(
          layer: ConflictLayer.android,
          severity: ConflictSeverity.error,
          title: 'compileSdk too low',
          description:
              'Package likely requires compileSdk $requiredCompileSdk but project has $compileSdk',
          filePath: 'android/app/build.gradle',
          fixes: fixes,
        ),
      );
    }
  }

  void _checkMinSdk(
    ProjectInfo project,
    PackageVersion packageVersion,
    List<Conflict> conflicts,
  ) {
    final minSdk = project.android.minSdk;
    if (minSdk == null) return;

    if (minSdk < 21) {
      conflicts.add(
        Conflict(
          layer: ConflictLayer.android,
          severity: ConflictSeverity.warning,
          title: 'minSdk below modern minimum',
          description:
              'Project minSdk is $minSdk. Most modern Flutter packages require minSdk 21+.',
          filePath: 'android/app/build.gradle',
          fixes: [
            Fix(
              filePath: 'android/app/build.gradle',
              description: 'Increase minSdk',
              currentValue: 'minSdk $minSdk',
              recommendedValue: 'minSdk 21',
            ),
          ],
        ),
      );
    }
  }

  void _checkKotlinVersion(
    ProjectInfo project,
    PackageVersion packageVersion,
    List<Conflict> conflicts,
  ) {
    final kotlinVersion = project.android.kotlinVersion;
    if (kotlinVersion == null) return;

    if (packageVersion.sdkConstraint != null) {
      try {
        final constraint = VersionConstraint.parse(
          packageVersion.sdkConstraint!,
        );
        if (constraint is VersionRange && constraint.min != null) {
          String? requiredKotlin;
          if (constraint.min! >= Version(3, 2, 0)) {
            requiredKotlin = '1.8.0';
          }

          if (requiredKotlin != null) {
            final currentParts = kotlinVersion.split('.');
            final requiredParts = requiredKotlin.split('.');
            if (currentParts.length >= 2 && requiredParts.length >= 2) {
              final currentMajorMinor =
                  int.parse(currentParts[0]) * 100 + int.parse(currentParts[1]);
              final requiredMajorMinor =
                  int.parse(requiredParts[0]) * 100 +
                  int.parse(requiredParts[1]);
              if (currentMajorMinor < requiredMajorMinor) {
                conflicts.add(
                  Conflict(
                    layer: ConflictLayer.android,
                    severity: ConflictSeverity.error,
                    title: 'Kotlin version too old',
                    description:
                        'Package likely requires Kotlin $requiredKotlin+ '
                        'but project uses Kotlin $kotlinVersion',
                    filePath: 'android/settings.gradle',
                    fixes: [
                      Fix(
                        filePath:
                            'android/settings.gradle or android/build.gradle',
                        description: 'Update Kotlin version',
                        currentValue: 'Kotlin $kotlinVersion',
                        recommendedValue: 'Kotlin 1.9.22 (recommended)',
                      ),
                    ],
                  ),
                );
              }
            }
          }
        }
      } catch (_) {}
    }
  }

  void _checkAgpChain(ProjectInfo project, List<Conflict> conflicts) {
    final agpVersion = project.android.agpVersion;
    final gradleVersion = project.android.gradleVersion;
    if (agpVersion == null || gradleVersion == null) return;

    final minGradle = CompatibilityMatrix.minGradleForAgp(agpVersion);
    if (minGradle != null) {
      try {
        final currentGradle = Version.parse(_normalizeVersion(gradleVersion));
        final requiredGradle = Version.parse(_normalizeVersion(minGradle));
        if (currentGradle < requiredGradle) {
          conflicts.add(
            Conflict(
              layer: ConflictLayer.cross,
              severity: ConflictSeverity.error,
              title: 'Gradle version incompatible with AGP',
              description:
                  'AGP $agpVersion requires Gradle $minGradle+ '
                  'but project has Gradle $gradleVersion',
              filePath: 'android/gradle/wrapper/gradle-wrapper.properties',
              fixes: [
                Fix(
                  filePath: 'android/gradle/wrapper/gradle-wrapper.properties',
                  description: 'Update Gradle wrapper distribution URL',
                  currentValue: 'Gradle $gradleVersion',
                  recommendedValue: 'Gradle $minGradle',
                ),
              ],
            ),
          );
        }
      } catch (_) {}
    }

    final minJdk = CompatibilityMatrix.minJdkForAgp(agpVersion);
    if (minJdk != null && project.android.javaVersion != null) {
      final currentJdk = int.tryParse(project.android.javaVersion!);
      if (currentJdk != null && currentJdk < minJdk) {
        conflicts.add(
          Conflict(
            layer: ConflictLayer.cross,
            severity: ConflictSeverity.error,
            title: 'JDK version too old for AGP',
            description:
                'AGP $agpVersion requires JDK $minJdk+ '
                'but project specifies JDK $currentJdk',
            filePath: 'android/app/build.gradle',
            fixes: [
              Fix(
                filePath: 'android/app/build.gradle',
                description: 'Update Java compatibility version',
                currentValue: 'JavaVersion.VERSION_$currentJdk',
                recommendedValue: 'JavaVersion.VERSION_$minJdk',
              ),
            ],
          ),
        );
      }
    }
  }

  String _normalizeVersion(String version) {
    final parts = version.split('.');
    while (parts.length < 3) {
      parts.add('0');
    }
    return parts.join('.');
  }
}
