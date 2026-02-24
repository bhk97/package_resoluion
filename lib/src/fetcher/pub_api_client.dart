import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/package_info.dart';

class PubApiClient {
  static const _baseUrl = 'https://pub.dev/api/packages';

  final http.Client _httpClient;

  PubApiClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  Future<PackageInfo> fetchPackage(String packageName) async {
    final url = Uri.parse('$_baseUrl/$packageName');
    final response = await _httpClient.get(
      url,
      headers: {'Accept': 'application/vnd.pub.v2+json'},
    );

    if (response.statusCode == 404) {
      throw PackageNotFoundException(packageName);
    }

    if (response.statusCode != 200) {
      throw PubApiException(
        'Failed to fetch package "$packageName": ${response.statusCode}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return _parsePackageInfo(json);
  }

  Future<PackageVersion> fetchLatestVersion(String packageName) async {
    final info = await fetchPackage(packageName);
    final latest = info.versions.lastWhere(
      (v) => !v.isRetracted,
      orElse: () => info.versions.last,
    );
    return latest;
  }

  PackageInfo _parsePackageInfo(Map<String, dynamic> json) {
    final name = json['name'] as String;
    final latest = json['latest'] as Map<String, dynamic>;
    final latestVersion = latest['version'] as String;

    final versionsJson = json['versions'] as List<dynamic>;
    final versions = versionsJson.map((v) {
      final vMap = v as Map<String, dynamic>;
      return _parseVersion(vMap);
    }).toList();

    return PackageInfo(
      name: name,
      latestVersion: latestVersion,
      versions: versions,
    );
  }

  PackageVersion _parseVersion(Map<String, dynamic> versionJson) {
    final version = versionJson['version'] as String;
    final isRetracted = versionJson['retracted'] == true;
    final pubspec = versionJson['pubspec'] as Map<String, dynamic>? ?? {};
    final environment = pubspec['environment'] as Map<String, dynamic>? ?? {};
    final deps = pubspec['dependencies'] as Map<String, dynamic>? ?? {};
    final devDeps = pubspec['dev_dependencies'] as Map<String, dynamic>? ?? {};

    final flutter = pubspec['flutter'] as Map<String, dynamic>?;
    final plugin = flutter?['plugin'] as Map<String, dynamic>?;
    final platforms = plugin?['platforms'] as Map<String, dynamic>?;
    final platformList =
        platforms?.keys.map((k) => k.toString()).toList() ?? <String>[];

    return PackageVersion(
      version: version,
      sdkConstraint: environment['sdk']?.toString(),
      flutterConstraint: environment['flutter']?.toString(),
      dependencies: _cleanDeps(deps),
      devDependencies: _cleanDeps(devDeps),
      isRetracted: isRetracted,
      platforms: platformList,
    );
  }

  Map<String, dynamic> _cleanDeps(Map<String, dynamic> deps) {
    final cleaned = <String, dynamic>{};
    for (final entry in deps.entries) {
      final value = entry.value;
      if (value is Map && value.containsKey('sdk')) continue;
      cleaned[entry.key] = value;
    }
    return cleaned;
  }

  void dispose() {
    _httpClient.close();
  }
}

class PackageNotFoundException implements Exception {
  final String packageName;
  PackageNotFoundException(this.packageName);

  @override
  String toString() => 'Package "$packageName" not found on pub.dev';
}

class PubApiException implements Exception {
  final String message;
  PubApiException(this.message);

  @override
  String toString() => message;
}
