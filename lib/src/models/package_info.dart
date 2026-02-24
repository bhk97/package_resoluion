class PackageInfo {
  const PackageInfo({
    required this.name,
    required this.latestVersion,
    required this.versions,
  });

  final String name;
  final String latestVersion;
  final List<PackageVersion> versions;

  PackageVersion? getVersion(String? version) {
    if (version == null) {
      return versions.isNotEmpty ? versions.last : null;
    }
    try {
      return versions.firstWhere((v) => v.version == version);
    } catch (_) {
      return null;
    }
  }
}

class PackageVersion {
  const PackageVersion({
    required this.version,
    required this.sdkConstraint,
    required this.flutterConstraint,
    required this.dependencies,
    required this.devDependencies,
    this.isRetracted = false,
    this.platforms = const [],
  });

  final String version;
  final String? sdkConstraint;
  final String? flutterConstraint;
  final Map<String, dynamic> dependencies;
  final Map<String, dynamic> devDependencies;
  final bool isRetracted;
  final List<String> platforms;
}
