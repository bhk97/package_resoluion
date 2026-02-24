import '../models/conflict.dart';
import '../models/package_info.dart';
import '../models/project_info.dart';

import 'dart_checker.dart';
import 'android_checker.dart';
import 'ios_checker.dart';

class ConflictDetector {
  final DartChecker _dartChecker;
  final AndroidChecker _androidChecker;
  final IosChecker _iosChecker;

  ConflictDetector({
    DartChecker? dartChecker,
    AndroidChecker? androidChecker,
    IosChecker? iosChecker,
  })  : _dartChecker = dartChecker ?? DartChecker(),
        _androidChecker = androidChecker ?? AndroidChecker(),
        _iosChecker = iosChecker ?? IosChecker();

  AnalysisReport analyze(ProjectInfo project, PackageVersion packageVersion) {
    final allConflicts = <Conflict>[];

    allConflicts.addAll(_dartChecker.check(project, packageVersion));
    allConflicts.addAll(_androidChecker.check(project, packageVersion));
    allConflicts.addAll(_iosChecker.check(project, packageVersion));

    final safeCombo = _buildSafeVersionCombo(
      project,
      packageVersion,
      allConflicts,
    );

    final scanSummary = ScanSummary(
      directDepsCount: project.pubspec.dependencies.length,
      devDepsCount: project.pubspec.devDependencies.length,
      transitiveDepsCount: project.lockfile.packages.length,
      androidFound: project.android.found,
      iosFound: project.ios.found,
    );

    return AnalysisReport(
      conflicts: allConflicts,
      safeVersionCombo: safeCombo,
      scanSummary: scanSummary,
    );
  }

  Map<String, VersionRecommendation> _buildSafeVersionCombo(
    ProjectInfo project,
    PackageVersion packageVersion,
    List<Conflict> conflicts,
  ) {
    final combo = <String, VersionRecommendation>{};

    combo['Dart SDK'] = VersionRecommendation(
      component: 'Dart SDK',
      current: project.pubspec.sdkConstraint ?? 'not set',
      recommended: packageVersion.sdkConstraint ?? 'any',
      needsChange: conflicts.any((c) => c.title.contains('SDK constraint')),
      filePath: 'pubspec.yaml',
    );

    combo['Flutter SDK'] = VersionRecommendation(
      component: 'Flutter SDK',
      current: project.flutterSdk.flutterVersion,
      recommended: packageVersion.flutterConstraint ?? 'any',
      needsChange: conflicts.any((c) => c.title.contains('Flutter SDK')),
    );

    if (project.android.found) {
      combo['compileSdk'] = VersionRecommendation(
        component: 'compileSdk',
        current: '${project.android.compileSdk ?? "not set"}',
        recommended: _recommendedCompileSdk(project, conflicts),
        needsChange: conflicts.any((c) => c.title.contains('compileSdk')),
        filePath: 'android/app/build.gradle',
      );

      combo['AGP'] = VersionRecommendation(
        component: 'AGP',
        current: project.android.agpVersion ?? 'not set',
        recommended: _recommendedAgp(project, conflicts),
        needsChange: conflicts.any(
          (c) =>
              c.title.contains('AGP') ||
              c.fixes.any((f) => f.description.contains('AGP')),
        ),
        filePath: 'android/settings.gradle',
      );

      combo['Gradle'] = VersionRecommendation(
        component: 'Gradle',
        current: project.android.gradleVersion ?? 'not set',
        recommended: _recommendedGradle(project, conflicts),
        needsChange: conflicts.any(
          (c) =>
              c.title.contains('Gradle') ||
              c.fixes.any((f) => f.description.contains('Gradle')),
        ),
        filePath: 'android/gradle/wrapper/gradle-wrapper.properties',
      );

      combo['Kotlin'] = VersionRecommendation(
        component: 'Kotlin',
        current: project.android.kotlinVersion ?? 'not set',
        recommended: _recommendedKotlin(project, conflicts),
        needsChange: conflicts.any((c) => c.title.contains('Kotlin')),
        filePath: 'android/settings.gradle',
      );

      combo['JDK'] = VersionRecommendation(
        component: 'JDK',
        current: project.android.javaVersion ?? 'not set',
        recommended: _recommendedJdk(project, conflicts),
        needsChange: conflicts.any((c) => c.title.contains('JDK')),
        filePath: 'android/app/build.gradle',
      );
    }

    if (project.ios.found) {
      combo['iOS target'] = VersionRecommendation(
        component: 'iOS target',
        current: project.ios.deploymentTarget ?? 'not set',
        recommended: _recommendedIosTarget(project, conflicts),
        needsChange: conflicts.any((c) => c.title.contains('deployment')),
        filePath: 'ios/Podfile',
      );
    }

    return combo;
  }

  String _recommendedCompileSdk(ProjectInfo project, List<Conflict> conflicts) {
    for (final c in conflicts) {
      for (final f in c.fixes) {
        if (f.description.contains('compileSdk')) {
          return f.recommendedValue;
        }
      }
    }
    return '${project.android.compileSdk ?? "34"} ✅';
  }

  String _recommendedAgp(ProjectInfo project, List<Conflict> conflicts) {
    for (final c in conflicts) {
      for (final f in c.fixes) {
        if (f.description.contains('AGP')) {
          return f.recommendedValue;
        }
      }
    }
    return '${project.android.agpVersion ?? "unknown"} ✅';
  }

  String _recommendedGradle(ProjectInfo project, List<Conflict> conflicts) {
    for (final c in conflicts) {
      for (final f in c.fixes) {
        if (f.description.contains('Gradle')) {
          return f.recommendedValue;
        }
      }
    }
    return '${project.android.gradleVersion ?? "unknown"} ✅';
  }

  String _recommendedKotlin(ProjectInfo project, List<Conflict> conflicts) {
    for (final c in conflicts) {
      for (final f in c.fixes) {
        if (f.description.contains('Kotlin')) {
          return f.recommendedValue;
        }
      }
    }
    return '${project.android.kotlinVersion ?? "unknown"} ✅';
  }

  String _recommendedJdk(ProjectInfo project, List<Conflict> conflicts) {
    for (final c in conflicts) {
      for (final f in c.fixes) {
        if (f.description.contains('Java') || f.description.contains('JDK')) {
          return f.recommendedValue;
        }
      }
    }
    return '${project.android.javaVersion ?? "unknown"} ✅';
  }

  String _recommendedIosTarget(ProjectInfo project, List<Conflict> conflicts) {
    for (final c in conflicts) {
      for (final f in c.fixes) {
        if (f.description.contains('deployment') ||
            f.description.contains('iOS')) {
          return f.recommendedValue;
        }
      }
    }
    return '${project.ios.deploymentTarget ?? "unknown"} ✅';
  }
}
