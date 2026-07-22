part of 'yours_vault_service.dart';

class YoursVaultExportResult {
  final Directory directory;
  final int planCount;
  final int workoutCount;
  final int exerciseCount;
  final DateTime exportedAt;

  const YoursVaultExportResult({
    required this.directory,
    required this.planCount,
    required this.workoutCount,
    required this.exerciseCount,
    required this.exportedAt,
  });
}

class YoursVaultImportResult {
  final int importedPlans;
  final int importedExercises;
  final List<String> importedFiles;
  final List<String> skippedFiles;
  final List<YoursVaultImportFileResult> fileResults;
  final List<String> archiveFailures;
  final List<String> scannedSources;
  final List<String> unavailableSources;

  const YoursVaultImportResult({
    required this.importedPlans,
    required this.importedExercises,
    required this.importedFiles,
    required this.skippedFiles,
    this.fileResults = const [],
    this.archiveFailures = const [],
    this.scannedSources = const [],
    this.unavailableSources = const [],
  });

  List<YoursVaultImportFileResult> get failedFiles =>
      fileResults.where((result) => result.status == 'failed').toList();

  YoursVaultImportResult copyWith({
    List<String>? skippedFiles,
    List<YoursVaultImportFileResult>? fileResults,
    List<String>? archiveFailures,
    List<String>? scannedSources,
    List<String>? unavailableSources,
  }) {
    return YoursVaultImportResult(
      importedPlans: importedPlans,
      importedExercises: importedExercises,
      importedFiles: importedFiles,
      skippedFiles: skippedFiles ?? this.skippedFiles,
      fileResults: fileResults ?? this.fileResults,
      archiveFailures: archiveFailures ?? this.archiveFailures,
      scannedSources: scannedSources ?? this.scannedSources,
      unavailableSources: unavailableSources ?? this.unavailableSources,
    );
  }
}

class _YoursVaultInboxSelection {
  final String token;
  final Directory stagingDirectory;
  final List<String> scannedSources;
  final List<String> unavailableSources;
  final List<String> conflictFiles;

  const _YoursVaultInboxSelection({
    required this.token,
    required this.stagingDirectory,
    required this.scannedSources,
    required this.unavailableSources,
    required this.conflictFiles,
  });
}

class YoursVaultImportFileResult {
  final String fileName;
  final String type;
  final String status;
  final String message;
  final List<String> missingExercises;

  const YoursVaultImportFileResult({
    required this.fileName,
    required this.type,
    required this.status,
    required this.message,
    this.missingExercises = const [],
  });
}
