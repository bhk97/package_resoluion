class Conflict {
  const Conflict({
    required this.layer,
    required this.severity,
    required this.title,
    required this.description,
    required this.fixes,
    this.filePath,
    this.lineNumber,
  });

  final ConflictLayer layer;
  final ConflictSeverity severity;
  final String title;
  final String description;
  final List<Fix> fixes;
  final String? filePath;
  final int? lineNumber;
}

enum ConflictLayer { dart, android, ios, cross }

enum ConflictSeverity { error, warning, info }

class Fix {
  const Fix({
    required this.filePath,
    required this.description,
    required this.currentValue,
    required this.recommendedValue,
    this.lineNumber,
  });

  final String filePath;
  final String description;
  final String currentValue;
  final String recommendedValue;
  final int? lineNumber;
}

class AnalysisReport {
  const AnalysisReport({
    required this.conflicts,
    required this.safeVersionCombo,
    required this.scanSummary,
  });

  final List<Conflict> conflicts;
  final Map<String, VersionRecommendation> safeVersionCombo;
  final ScanSummary scanSummary;

  bool get hasConflicts =>
      conflicts.any((c) => c.severity == ConflictSeverity.error);

  int get errorCount =>
      conflicts.where((c) => c.severity == ConflictSeverity.error).length;

  int get warningCount =>
      conflicts.where((c) => c.severity == ConflictSeverity.warning).length;
}

class VersionRecommendation {
  const VersionRecommendation({
    required this.component,
    required this.current,
    required this.recommended,
    required this.needsChange,
    this.filePath,
  });

  final String component;
  final String current;
  final String recommended;
  final bool needsChange;
  final String? filePath;
}

class ScanSummary {
  const ScanSummary({
    required this.directDepsCount,
    required this.devDepsCount,
    required this.transitiveDepsCount,
    required this.androidFound,
    required this.iosFound,
  });

  final int directDepsCount;
  final int devDepsCount;
  final int transitiveDepsCount;
  final bool androidFound;
  final bool iosFound;
}
