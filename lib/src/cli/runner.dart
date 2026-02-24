import 'dart:io';

import 'package:args/args.dart';
import 'package:pub_semver/pub_semver.dart';

import '../engine/conflict_detector.dart';
import '../fetcher/pub_api_client.dart';
import '../models/package_info.dart';
import '../reporter/json_reporter.dart';
import '../reporter/terminal_reporter.dart';
import '../scanner/project_scanner.dart';

class CliRunner {
  final ProjectScanner _projectScanner;
  final PubApiClient _pubApiClient;
  final ConflictDetector _conflictDetector;
  final TerminalReporter _terminalReporter;
  final JsonReporter _jsonReporter;

  CliRunner({
    ProjectScanner? projectScanner,
    PubApiClient? pubApiClient,
    ConflictDetector? conflictDetector,
    TerminalReporter? terminalReporter,
    JsonReporter? jsonReporter,
  }) : _projectScanner = projectScanner ?? ProjectScanner(),
       _pubApiClient = pubApiClient ?? PubApiClient(),
       _conflictDetector = conflictDetector ?? ConflictDetector(),
       _terminalReporter = terminalReporter ?? TerminalReporter(),
       _jsonReporter = jsonReporter ?? JsonReporter();

  Future<int> run(List<String> args) async {
    final parser = ArgParser()
      ..addOption(
        'path',
        abbr: 'p',
        defaultsTo: '.',
        help: 'Path to Flutter project directory',
      )
      ..addOption(
        'add',
        abbr: 'a',
        help: 'Package name to analyze for addition',
      )
      ..addOption(
        'version',
        abbr: 'v',
        help: 'Specific version to check (default: latest)',
      )
      ..addFlag(
        'scan-only',
        negatable: false,
        help: 'Just scan project health without adding a package',
      )
      ..addFlag('json', negatable: false, help: 'Output as JSON')
      ..addFlag('verbose', negatable: false, help: 'Show debug info')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage info');

    late ArgResults results;
    try {
      results = parser.parse(args);
    } catch (e) {
      stderr.writeln('Error: $e');
      _printUsage(parser);
      return 1;
    }

    if (results['help'] as bool) {
      _printUsage(parser);
      return 0;
    }

    final scanOnly = results['scan-only'] as bool;
    final packageName = results['add'] as String?;
    final useJson = results['json'] as bool;
    final verbose = results['verbose'] as bool;
    final projectPath = Directory(results['path'] as String).absolute.path;

    if (!scanOnly && packageName == null) {
      stderr.writeln(
        'Error: Please specify a package with --add <package_name> '
        'or use --scan-only',
      );
      _printUsage(parser);
      return 1;
    }

    final pubspecFile = File('$projectPath/pubspec.yaml');
    if (!pubspecFile.existsSync()) {
      stderr.writeln(
        'Error: No pubspec.yaml found at "$projectPath". '
        'Is this a Flutter project?',
      );
      return 1;
    }

    try {
      if (verbose) print('Scanning project at $projectPath...');
      final project = await _projectScanner.scan(projectPath);

      if (scanOnly) {
        return _runScanOnly(project, useJson);
      }

      if (verbose) print('Fetching $packageName from pub.dev...');
      final packageInfo = await _pubApiClient.fetchPackage(packageName!);

      final requestedVersion = results['version'] as String?;
      PackageVersion? targetVersion;

      if (requestedVersion != null) {
        targetVersion = _findMatchingVersion(packageInfo, requestedVersion);
        if (targetVersion == null) {
          stderr.writeln(
            'Error: No version of $packageName matches "$requestedVersion"',
          );
          return 1;
        }
      } else {
        targetVersion = packageInfo.versions.lastWhere(
          (v) => !v.isRetracted,
          orElse: () => packageInfo.versions.last,
        );
      }

      if (verbose) print('Analyzing conflicts...');
      final report = _conflictDetector.analyze(project, targetVersion);

      if (useJson) {
        final json = _jsonReporter.toJson(
          report,
          project,
          packageName,
          targetVersion.version,
        );
        print(json);
      } else {
        _terminalReporter.printReport(
          report,
          project,
          packageName,
          targetVersion.version,
        );
      }

      return report.hasConflicts ? 1 : 0;
    } on PackageNotFoundException catch (e) {
      stderr.writeln('Error: $e');
      return 1;
    } on PubApiException catch (e) {
      stderr.writeln('Error: $e');
      return 1;
    } on FileSystemException catch (e) {
      stderr.writeln('Error: ${e.message} (${e.path})');
      return 1;
    } catch (e, st) {
      stderr.writeln('Unexpected error: $e');
      if (verbose) stderr.writeln(st);
      return 1;
    } finally {
      _pubApiClient.dispose();
    }
  }

  int _runScanOnly(project, bool useJson) {
    final dummyVersion = PackageVersion(
      version: 'scan',
      sdkConstraint: null,
      flutterConstraint: null,
      dependencies: {},
      devDependencies: {},
      platforms: [],
    );

    final report = _conflictDetector.analyze(project, dummyVersion);

    if (useJson) {
      final json = _jsonReporter.toJson(report, project, '(scan-only)', 'N/A');
      print(json);
    } else {
      _terminalReporter.printReport(report, project, '(scan-only)', 'N/A');
    }

    return report.hasConflicts ? 1 : 0;
  }

  PackageVersion? _findMatchingVersion(PackageInfo info, String constraintStr) {
    try {
      final constraint = VersionConstraint.parse(constraintStr);
      for (var i = info.versions.length - 1; i >= 0; i--) {
        final v = info.versions[i];
        if (v.isRetracted) continue;
        try {
          final version = Version.parse(v.version);
          if (constraint.allows(version)) return v;
        } catch (_) {}
      }
    } catch (_) {
      for (final v in info.versions.reversed) {
        if (v.version == constraintStr && !v.isRetracted) return v;
      }
    }
    return null;
  }

  void _printUsage(ArgParser parser) {
    print('');
    print('Flutter Dependency Resolver (fdr)');
    print(
      'Detect & resolve version conflicts across pubspec, Gradle, and CocoaPods.',
    );
    print('');
    print('USAGE:');
    print('  fdr --add <package_name> [options]');
    print('');
    print('OPTIONS:');
    print(parser.usage);
    print('');
    print('EXAMPLES:');
    print('  fdr --add firebase_auth');
    print('  fdr --path ./my_app --add supabase_flutter');
    print('  fdr --add camera --version ^0.10.0');
    print('  fdr --scan-only');
    print('  fdr --add firebase_auth --json');
    print('');
  }
}
