class ProjectInfo {
  const ProjectInfo({
    required this.projectPath,
    required this.projectName,
    required this.pubspec,
    required this.lockfile,
    required this.android,
    required this.ios,
    required this.flutterSdk,
  });

  final String projectPath;
  final String projectName;
  final PubspecInfo pubspec;
  final LockfileInfo lockfile;
  final AndroidInfo android;
  final IosInfo ios;
  final FlutterSdkInfo flutterSdk;
}

class PubspecInfo {
  const PubspecInfo({
    required this.sdkConstraint,
    required this.flutterConstraint,
    required this.dependencies,
    required this.devDependencies,
    required this.dependencyOverrides,
  });

  final String? sdkConstraint;
  final String? flutterConstraint;
  final Map<String, dynamic> dependencies;
  final Map<String, dynamic> devDependencies;
  final Map<String, dynamic> dependencyOverrides;
}

class LockfileInfo {
  const LockfileInfo({
    required this.packages,
  });

  final Map<String, LockedPackage> packages;
}

class LockedPackage {
  const LockedPackage({
    required this.name,
    required this.version,
    required this.source,
  });

  final String name;
  final String version;
  final String source;
}

class AndroidInfo {
  const AndroidInfo({
    required this.found,
    this.compileSdk,
    this.minSdk,
    this.targetSdk,
    this.agpVersion,
    this.kotlinVersion,
    this.gradleVersion,
    this.javaVersion,
    this.ndkVersion,
  });

  final bool found;
  final int? compileSdk;
  final int? minSdk;
  final int? targetSdk;
  final String? agpVersion;
  final String? kotlinVersion;
  final String? gradleVersion;
  final String? javaVersion;
  final String? ndkVersion;
}

class IosInfo {
  const IosInfo({
    required this.found,
    this.deploymentTarget,
    this.useFrameworks,
  });

  final bool found;
  final String? deploymentTarget;
  final bool? useFrameworks;
}

class FlutterSdkInfo {
  const FlutterSdkInfo({
    required this.flutterVersion,
    required this.dartVersion,
    required this.channel,
  });

  final String flutterVersion;
  final String dartVersion;
  final String channel;
}
