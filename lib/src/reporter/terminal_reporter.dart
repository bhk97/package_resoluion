import '../models/conflict.dart';
import '../models/project_info.dart';

class TerminalReporter {
  static const _reset = '\x1B[0m';
  static const _bold = '\x1B[1m';
  static const _dim = '\x1B[2m';
  static const _red = '\x1B[31m';
  static const _green = '\x1B[32m';
  static const _yellow = '\x1B[33m';
  static const _blue = '\x1B[34m';
  static const _cyan = '\x1B[36m';
  static const _white = '\x1B[37m';
  static const _bgRed = '\x1B[41m';
  static const _bgGreen = '\x1B[42m';
  static const _bgYellow = '\x1B[43m';
  static const _bgBlue = '\x1B[44m';

  void printReport(
    AnalysisReport report,
    ProjectInfo project,
    String packageName,
    String packageVersion,
  ) {
    _printHeader(project, packageName, packageVersion);
    _printScanSummary(report, project);
    _printConflicts(report);
    _printSafeCombo(report);
    _printActionItems(report);
  }

  void _printHeader(
    ProjectInfo project,
    String packageName,
    String packageVersion,
  ) {
    print('');
    _printBox([
      '🔍 Flutter Dependency Resolver (fdr)',
      '',
      'Project:  ${project.projectName}',
      'Flutter:  ${project.flutterSdk.flutterVersion} (${project.flutterSdk.channel}) │ Dart: ${project.flutterSdk.dartVersion}',
      'Package:  $packageName (adding: $packageVersion)',
    ]);
  }

  void _printScanSummary(AnalysisReport report, ProjectInfo project) {
    print('');
    print('$_bold${_cyan}📋 SCANNING PROJECT...$_reset');
    _printScanLine(
      'pubspec.yaml',
      '${report.scanSummary.directDepsCount} deps, ${report.scanSummary.devDepsCount} dev_deps',
    );
    _printScanLine(
      'pubspec.lock',
      '${report.scanSummary.transitiveDepsCount} transitive deps',
    );

    if (project.android.found) {
      final agp = project.android.agpVersion ?? '?';
      final kotlin = project.android.kotlinVersion ?? '?';
      _printScanLine('android/build.gradle', 'AGP $agp, Kotlin $kotlin');

      final compileSdk = project.android.compileSdk ?? '?';
      final minSdk = project.android.minSdk ?? '?';
      _printScanLine(
        'android/app/build.gradle',
        'compileSdk $compileSdk, minSdk $minSdk',
      );

      final gradle = project.android.gradleVersion ?? '?';
      _printScanLine('gradle-wrapper.properties', 'Gradle $gradle');
    } else {
      _printScanLine('android/', 'not found', ok: false);
    }

    if (project.ios.found) {
      final target = project.ios.deploymentTarget ?? '?';
      _printScanLine('ios/Podfile', 'platform :ios, \'$target\'');
    } else {
      _printScanLine('ios/', 'not found', ok: false);
    }

    _printScanLine('Flutter SDK', project.flutterSdk.flutterVersion);
  }

  void _printConflicts(AnalysisReport report) {
    print('');
    if (report.conflicts.isEmpty) {
      print(
        '$_bold$_green══════════════════════════════════════════════════════════════$_reset',
      );
      print('$_bold$_green  ✅ NO CONFLICTS DETECTED$_reset');
      print(
        '$_bold$_green══════════════════════════════════════════════════════════════$_reset',
      );
      return;
    }

    final errors = report.errorCount;
    final warnings = report.warningCount;
    print(
      '$_bold$_red══════════════════════════════════════════════════════════════$_reset',
    );
    print(
      '$_bold$_red  ⚠️  $errors ERROR${errors != 1 ? 'S' : ''}, $warnings WARNING${warnings != 1 ? 'S' : ''} DETECTED$_reset',
    );
    print(
      '$_bold$_red══════════════════════════════════════════════════════════════$_reset',
    );

    for (var i = 0; i < report.conflicts.length; i++) {
      _printConflict(i + 1, report.conflicts[i]);
    }
  }

  void _printConflict(int index, Conflict conflict) {
    print('');
    final layerTag = _layerTag(conflict.layer);
    final severityIcon = conflict.severity == ConflictSeverity.error
        ? '$_red❌'
        : conflict.severity == ConflictSeverity.warning
            ? '$_yellow⚠️'
            : '$_blue ℹ️';

    print(
      '$_bold┌─ CONFLICT $index ─────────────────────────── $layerTag ──────┐$_reset',
    );
    print('$_bold│$_reset');
    print('$_bold│  $severityIcon  ${conflict.title}$_reset');
    print('$_bold│$_reset');
    print('$_bold│$_dim  ${conflict.description}$_reset');
    print('$_bold│$_reset');

    if (conflict.filePath != null) {
      print(
        '$_bold│$_dim  📁 ${conflict.filePath}${conflict.lineNumber != null ? ':${conflict.lineNumber}' : ''}$_reset',
      );
      print('$_bold│$_reset');
    }

    for (final fix in conflict.fixes) {
      print('$_bold│  $_green📝 FIX: ${fix.description}$_reset');
      print('$_bold│$_red    - ${fix.currentValue}$_reset');
      print('$_bold│$_green    + ${fix.recommendedValue}$_reset');
      if (fix.filePath.isNotEmpty) {
        print('$_bold│$_dim    📁 ${fix.filePath}$_reset');
      }
      print('$_bold│$_reset');
    }

    print(
      '$_bold└──────────────────────────────────────────────────────────────┘$_reset',
    );
  }

  void _printSafeCombo(AnalysisReport report) {
    if (report.safeVersionCombo.isEmpty) return;

    print('');
    print(
      '$_bold$_green══════════════════════════════════════════════════════════════$_reset',
    );
    print(
      '${report.hasConflicts ? "$_bold$_yellow  📊 RECOMMENDED VERSION COMBO" : "$_bold$_green  ✅ SAFE VERSION COMBO"}$_reset',
    );
    print(
      '$_bold$_green══════════════════════════════════════════════════════════════$_reset',
    );
    print('');

    print(
      '$_bold  ┌────────────────────────────┬──────────────────┬──────────────────┐$_reset',
    );
    print(
      '$_bold  │ Component                  │ Current          │ Recommended      │$_reset',
    );
    print(
      '$_bold  ├────────────────────────────┼──────────────────┼──────────────────┤$_reset',
    );

    for (final entry in report.safeVersionCombo.entries) {
      final rec = entry.value;
      final currentColor = rec.needsChange ? _red : _green;
      final recColor = rec.needsChange ? _yellow : _green;
      final component = rec.component.padRight(26);
      final current = rec.current.padRight(16);
      final recommended = rec.recommended.padRight(16);
      print(
        '$_bold  │$_reset $component$_bold│$_reset $currentColor$current$_reset$_bold│$_reset $recColor$recommended$_reset$_bold│$_reset',
      );
    }

    print(
      '$_bold  └────────────────────────────┴──────────────────┴──────────────────┘$_reset',
    );
  }

  void _printActionItems(AnalysisReport report) {
    final filesToModify = <String>[];
    for (final conflict in report.conflicts) {
      for (final fix in conflict.fixes) {
        final item = '${fix.filePath} → ${fix.recommendedValue}';
        if (!filesToModify.contains(item)) {
          filesToModify.add(item);
        }
      }
    }

    if (filesToModify.isEmpty) {
      print('');
      print(
        '$_bold$_green  💡 No changes needed — you can safely add this package!$_reset',
      );
      print('$_dim     Run: flutter pub add <package_name>$_reset');
      print('');
      return;
    }

    print('');
    print('$_bold  📄 Files to modify:$_reset');
    for (var i = 0; i < filesToModify.length; i++) {
      print('$_dim     ${i + 1}. ${filesToModify[i]}$_reset');
    }

    print('');
    print('$_bold$_cyan  💡 After making changes, run:$_reset');
    print('$_dim     flutter pub get && cd ios && pod install$_reset');
    print('');
  }


  void _printBox(List<String> lines) {
    final maxLen = lines.fold<int>(
      0,
      (max, l) => l.length > max ? l.length : max,
    );
    final width = maxLen + 4;

    print('$_bold$_blue╔${"═" * width}╗$_reset');
    for (final line in lines) {
      print(
        '$_bold$_blue║$_reset  ${line.padRight(width - 2)}$_bold$_blue║$_reset',
      );
    }
    print('$_bold$_blue╚${"═" * width}╝$_reset');
  }

  void _printScanLine(String file, String detail, {bool ok = true}) {
    final icon = ok ? '$_green✓' : '$_yellow⚠';
    print('  $icon $_white$file$_reset $_dim($detail)$_reset');
  }

  String _layerTag(ConflictLayer layer) {
    switch (layer) {
      case ConflictLayer.dart:
        return '$_bgBlue$_white DART $_reset';
      case ConflictLayer.android:
        return '$_bgGreen$_white ANDROID $_reset';
      case ConflictLayer.ios:
        return '$_bgYellow$_white iOS $_reset';
      case ConflictLayer.cross:
        return '$_bgRed$_white CROSS $_reset';
    }
  }
}
