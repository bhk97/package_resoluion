import '../models/conflict.dart';
import '../models/package_info.dart';
import '../models/project_info.dart';

class IosChecker {
  List<Conflict> check(ProjectInfo project, PackageVersion packageVersion) {
    final conflicts = <Conflict>[];

    if (!project.ios.found) {
      return conflicts;
    }

    if (!packageVersion.platforms.contains('ios') &&
        packageVersion.platforms.isNotEmpty) {
      return conflicts;
    }

    _checkDeploymentTarget(project, packageVersion, conflicts);

    return conflicts;
  }

  void _checkDeploymentTarget(
    ProjectInfo project,
    PackageVersion packageVersion,
    List<Conflict> conflicts,
  ) {
    final deploymentTarget = project.ios.deploymentTarget;
    if (deploymentTarget == null) return;

    String? requiredIosVersion;
    if (packageVersion.sdkConstraint != null) {
      try {
        if (packageVersion.sdkConstraint!.contains('>=3.2') ||
            packageVersion.sdkConstraint!.contains('>=3.3') ||
            packageVersion.sdkConstraint!.contains('>=3.4') ||
            packageVersion.sdkConstraint!.contains('>=3.5') ||
            packageVersion.sdkConstraint!.contains('>=3.6')) {
          requiredIosVersion = '13.0';
        } else if (packageVersion.sdkConstraint!.contains('>=3.0') ||
            packageVersion.sdkConstraint!.contains('>=3.1')) {
          requiredIosVersion = '12.0';
        }
      } catch (_) {}
    }

    if (requiredIosVersion != null) {
      final currentVersion = _parseVersion(deploymentTarget);
      final requiredVersion = _parseVersion(requiredIosVersion);

      if (currentVersion < requiredVersion) {
        conflicts.add(
          Conflict(
            layer: ConflictLayer.ios,
            severity: ConflictSeverity.error,
            title: 'iOS deployment target too low',
            description:
                'Package likely requires iOS $requiredIosVersion+ '
                'but Podfile sets platform :ios, \'$deploymentTarget\'',
            filePath: 'ios/Podfile',
            fixes: [
              Fix(
                filePath: 'ios/Podfile',
                description: 'Update iOS deployment target',
                currentValue: "platform :ios, '$deploymentTarget'",
                recommendedValue: "platform :ios, '$requiredIosVersion'",
              ),
            ],
          ),
        );
      }
    }
  }

  double _parseVersion(String version) {
    try {
      return double.parse(version);
    } catch (_) {
      return 0.0;
    }
  }
}
