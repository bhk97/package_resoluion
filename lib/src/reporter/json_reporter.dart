import 'dart:convert';
import 'dart:io';

import '../models/conflict.dart';
import '../models/project_info.dart';

class JsonReporter {
  String toJson(
    AnalysisReport report,
    ProjectInfo project,
    String packageName,
    String packageVersion,
  ) {
    final json = {
      'project': {
        'name': project.projectName,
        'path': project.projectPath,
        'flutter_version': project.flutterSdk.flutterVersion,
        'dart_version': project.flutterSdk.dartVersion,
      },
      'package': {'name': packageName, 'version': packageVersion},
      'summary': {
        'direct_deps': report.scanSummary.directDepsCount,
        'dev_deps': report.scanSummary.devDepsCount,
        'transitive_deps': report.scanSummary.transitiveDepsCount,
        'errors': report.errorCount,
        'warnings': report.warningCount,
        'has_conflicts': report.hasConflicts,
      },
      'conflicts': report.conflicts
          .map(
            (c) => {
              'layer': c.layer.name,
              'severity': c.severity.name,
              'title': c.title,
              'description': c.description,
              'file': c.filePath,
              'line': c.lineNumber,
              'fixes': c.fixes
                  .map(
                    (f) => {
                      'file': f.filePath,
                      'description': f.description,
                      'current': f.currentValue,
                      'recommended': f.recommendedValue,
                      'line': f.lineNumber,
                    },
                  )
                  .toList(),
            },
          )
          .toList(),
      'recommendations': report.safeVersionCombo.map(
        (key, value) => MapEntry(key, {
          'component': value.component,
          'current': value.current,
          'recommended': value.recommended,
          'needs_change': value.needsChange,
          'file': value.filePath,
        }),
      ),
    };

    return const JsonEncoder.withIndent('  ').convert(json);
  }

  void writeToFile(String jsonString, String outputPath) {
    File(outputPath).writeAsStringSync(jsonString);
  }
}
