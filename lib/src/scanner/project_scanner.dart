import '../models/project_info.dart';
import 'pubspec_scanner.dart';
import 'gradle_scanner.dart';
import 'podfile_scanner.dart';
import 'flutter_sdk_scanner.dart';

class ProjectScanner {
  final PubspecScanner _pubspecScanner;
  final GradleScanner _gradleScanner;
  final PodfileScanner _podfileScanner;
  final FlutterSdkScanner _flutterSdkScanner;

  ProjectScanner({
    PubspecScanner? pubspecScanner,
    GradleScanner? gradleScanner,
    PodfileScanner? podfileScanner,
    FlutterSdkScanner? flutterSdkScanner,
  }) : _pubspecScanner = pubspecScanner ?? PubspecScanner(),
       _gradleScanner = gradleScanner ?? GradleScanner(),
       _podfileScanner = podfileScanner ?? PodfileScanner(),
       _flutterSdkScanner = flutterSdkScanner ?? FlutterSdkScanner();

  Future<ProjectInfo> scan(String projectPath) async {
    final projectName = _pubspecScanner.getProjectName(projectPath);
    final pubspec = _pubspecScanner.scanPubspec(projectPath);
    final lockfile = _pubspecScanner.scanLockfile(projectPath);
    final android = _gradleScanner.scan(projectPath);
    final ios = _podfileScanner.scan(projectPath);
    final flutterSdk = await _flutterSdkScanner.scan();

    return ProjectInfo(
      projectPath: projectPath,
      projectName: projectName,
      pubspec: pubspec,
      lockfile: lockfile,
      android: android,
      ios: ios,
      flutterSdk: flutterSdk,
    );
  }
}
