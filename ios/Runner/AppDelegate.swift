import Flutter
import PhotosUI
import UIKit
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, UIDocumentPickerDelegate, PHPickerViewControllerDelegate {
  private struct VaultInboxSession {
    let stagingDirectory: URL
    let files: [String: [URL]]
  }

  private let iCloudContainerIdentifier = "iCloud.com.ly.yours"
  private var pendingICloudBackupPickResult: FlutterResult?
  private var pendingPosterBackgroundPickResult: FlutterResult?
  private var vaultInboxSessions: [String: VaultInboxSession] = [:]

  private func text(_ key: String) -> String {
    NSLocalizedString(key, comment: "")
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "yours/files",
      binaryMessenger: engineBridge.pluginRegistry.registrar(forPlugin: "YoursFiles")!.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handleFilesCall(call, result: result)
    }
    let photosChannel = FlutterMethodChannel(
      name: "yours/photos",
      binaryMessenger: engineBridge.pluginRegistry.registrar(forPlugin: "YoursPhotos")!.messenger()
    )
    photosChannel.setMethodCallHandler { [weak self] call, result in
      self?.handlePhotosCall(call, result: result)
    }
  }

  private func handleFilesCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getICloudStatus":
      result(iCloudStatus())
    case "exportBackupToICloudDrive":
      exportFileArgument(call, folderName: "Backups", result: result)
    case "exportVaultToICloudDrive":
      exportDirectoryArgument(call, folderName: "YoursVault", result: result)
    case "pickICloudBackup":
      pickICloudBackup(result: result)
    case "prepareDefaultVaultInboxImport":
      prepareDefaultVaultInboxImport(result: result)
    case "completeVaultInboxImport":
      completeVaultInboxImport(call, result: result)
    case "syncBackupToPublicDocuments", "syncVaultToPublicDocuments", "importPublicBackup", "pickPublicBackup":
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handlePhotosCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "pickPosterBackground":
      pickPosterBackground(result: result)
    case "saveImageToPhotos":
      saveImageToPhotos(call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func presenter() -> UIViewController? {
    UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene })
      .flatMap({ $0.windows })
      .first(where: { $0.isKeyWindow })?
      .rootViewController
  }

  private func pickPosterBackground(result: @escaping FlutterResult) {
    if pendingPosterBackgroundPickResult != nil {
      result(FlutterError(code: "photo_picker_busy", message: text("photo_picker_busy"), details: nil))
      return
    }
    guard let presenter = presenter() else {
      result(FlutterError(code: "photo_picker_unavailable", message: text("photo_picker_unavailable"), details: nil))
      return
    }
    pendingPosterBackgroundPickResult = result
    var configuration = PHPickerConfiguration(photoLibrary: .shared())
    configuration.filter = .images
    configuration.selectionLimit = 1
    let picker = PHPickerViewController(configuration: configuration)
    picker.delegate = self
    presenter.present(picker, animated: true)
  }

  private func saveImageToPhotos(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
          let bytes = arguments["bytes"] as? FlutterStandardTypedData,
          let image = UIImage(data: bytes.data) else {
      result(FlutterError(code: "bad_args", message: text("photo_save_bad_args"), details: nil))
      return
    }

    PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
      guard status == .authorized || status == .limited else {
        DispatchQueue.main.async {
          result(FlutterError(code: "photo_permission_denied", message: self.text("photo_permission_denied"), details: nil))
        }
        return
      }
      PHPhotoLibrary.shared().performChanges({
        PHAssetChangeRequest.creationRequestForAsset(from: image)
      }) { success, error in
        DispatchQueue.main.async {
          if success {
            result(true)
          } else {
            result(FlutterError(code: "photo_save_failed", message: error?.localizedDescription ?? self.text("photo_save_failed"), details: nil))
          }
        }
      }
    }
  }

  private func iCloudStatus() -> [String: Any] {
    guard FileManager.default.ubiquityIdentityToken != nil else {
      return [
        "available": false,
        "state": "signedOut",
        "message": text("icloud_signed_out")
      ]
    }

    guard let root = iCloudDocumentsDirectory(create: true) else {
      return [
        "available": false,
        "state": "containerUnavailable",
        "message": text("icloud_container_unavailable")
      ]
    }

    return [
      "available": true,
      "state": "available",
      "path": root.path,
      "message": text("icloud_available")
    ]
  }

  private func exportFileArgument(
    _ call: FlutterMethodCall,
    folderName: String,
    result: @escaping FlutterResult
  ) {
    guard let arguments = call.arguments as? [String: Any],
          let sourcePath = arguments["path"] as? String else {
      result(FlutterError(code: "bad_args", message: text("missing_file_path"), details: nil))
      return
    }

    do {
      let destination = try copyFileToICloud(sourcePath: sourcePath, folderName: folderName)
      result(destination.path)
    } catch {
      result(FlutterError(code: "icloud_export_failed", message: error.localizedDescription, details: nil))
    }
  }

  private func exportDirectoryArgument(
    _ call: FlutterMethodCall,
    folderName: String,
    result: @escaping FlutterResult
  ) {
    guard let arguments = call.arguments as? [String: Any],
          let sourcePath = arguments["path"] as? String else {
      result(FlutterError(code: "bad_args", message: text("missing_directory_path"), details: nil))
      return
    }

    do {
      let destination = try copyDirectoryToICloud(sourcePath: sourcePath, folderName: folderName)
      result(destination.path)
    } catch {
      result(FlutterError(code: "icloud_export_failed", message: error.localizedDescription, details: nil))
    }
  }

  private func iCloudDocumentsDirectory(create: Bool) -> URL? {
    guard let container = FileManager.default.url(forUbiquityContainerIdentifier: iCloudContainerIdentifier) else {
      return nil
    }
    let documents = container.appendingPathComponent("Documents", isDirectory: true)
    if create {
      try? FileManager.default.createDirectory(at: documents, withIntermediateDirectories: true)
    }
    return documents
  }

  private func copyFileToICloud(sourcePath: String, folderName: String) throws -> URL {
    guard let root = iCloudDocumentsDirectory(create: true) else {
      throw NSError(
        domain: "YoursFiles",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: text("icloud_container_unavailable")]
      )
    }

    let source = URL(fileURLWithPath: sourcePath)
    let folder = root.appendingPathComponent(folderName, isDirectory: true)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    let destination = folder.appendingPathComponent(source.lastPathComponent)
    if FileManager.default.fileExists(atPath: destination.path) {
      try FileManager.default.removeItem(at: destination)
    }
    try FileManager.default.copyItem(at: source, to: destination)
    return destination
  }

  private func copyDirectoryToICloud(sourcePath: String, folderName: String) throws -> URL {
    guard let root = iCloudDocumentsDirectory(create: true) else {
      throw NSError(
        domain: "YoursFiles",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: text("icloud_container_unavailable")]
      )
    }

    let source = URL(fileURLWithPath: sourcePath)
    let destination = root.appendingPathComponent(folderName, isDirectory: true)
    try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)

    // inbox belongs to the user. Replace only the directories exported by Yours.
    for name in ["plans", "logs", "exercises", "reports"] {
      let sourceChild = source.appendingPathComponent(name, isDirectory: true)
      guard FileManager.default.fileExists(atPath: sourceChild.path) else {
        continue
      }
      let destinationChild = destination.appendingPathComponent(name, isDirectory: true)
      if FileManager.default.fileExists(atPath: destinationChild.path) {
        try FileManager.default.removeItem(at: destinationChild)
      }
      try FileManager.default.copyItem(at: sourceChild, to: destinationChild)
    }

    let sourceManifest = source.appendingPathComponent("manifest.json")
    if FileManager.default.fileExists(atPath: sourceManifest.path) {
      let destinationManifest = destination.appendingPathComponent("manifest.json")
      if FileManager.default.fileExists(atPath: destinationManifest.path) {
        try FileManager.default.removeItem(at: destinationManifest)
      }
      try FileManager.default.copyItem(at: sourceManifest, to: destinationManifest)
    }
    return destination
  }

  private func pickICloudBackup(result: @escaping FlutterResult) {
    if pendingICloudBackupPickResult != nil {
      result(FlutterError(code: "icloud_picker_busy", message: text("icloud_picker_busy"), details: nil))
      return
    }

    guard FileManager.default.ubiquityIdentityToken != nil else {
      result(FlutterError(code: "icloud_signed_out", message: text("icloud_signed_out"), details: nil))
      return
    }

    guard let presenter = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene })
      .flatMap({ $0.windows })
      .first(where: { $0.isKeyWindow })?
      .rootViewController else {
      result(FlutterError(code: "icloud_picker_unavailable", message: text("icloud_picker_unavailable"), details: nil))
      return
    }

    pendingICloudBackupPickResult = result
    let picker: UIDocumentPickerViewController
    if #available(iOS 14.0, *) {
      let zipType = UTType(filenameExtension: "zip") ?? .data
      picker = UIDocumentPickerViewController(forOpeningContentTypes: [zipType], asCopy: true)
    } else {
      picker = legacyZipDocumentPicker()
    }
    picker.delegate = self
    picker.allowsMultipleSelection = false
    presenter.present(picker, animated: true)
  }

  @available(iOS, introduced: 11.0, deprecated: 14.0)
  private func legacyZipDocumentPicker() -> UIDocumentPickerViewController {
    UIDocumentPickerViewController(
      documentTypes: ["com.pkware.zip-archive", "public.zip-archive", "public.archive"],
      in: .import
    )
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    pendingICloudBackupPickResult?(nil)
    pendingICloudBackupPickResult = nil
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    guard let result = pendingICloudBackupPickResult else {
      return
    }
    pendingICloudBackupPickResult = nil

    guard let source = urls.first else {
      result(nil)
      return
    }

    let needsStop = source.startAccessingSecurityScopedResource()
    defer {
      if needsStop {
        source.stopAccessingSecurityScopedResource()
      }
    }

    do {
      let destination = try copyPickedBackupToTemporaryDirectory(source: source)
      result(destination.path)
    } catch {
      result(FlutterError(code: "icloud_pick_failed", message: error.localizedDescription, details: nil))
    }
  }

  private func prepareDefaultVaultInboxImport(result: @escaping FlutterResult) {
    let fileManager = FileManager.default
    let token = UUID().uuidString
    let stagingDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
      .appendingPathComponent("YoursVaultImports", isDirectory: true)
      .appendingPathComponent(token, isDirectory: true)
    let stagingInbox = stagingDirectory.appendingPathComponent("inbox", isDirectory: true)

    do {
      try fileManager.createDirectory(at: stagingInbox, withIntermediateDirectories: true)
      var unavailableSources: [String] = []
      var candidates: [(url: URL, priority: Int)] = []

      if let iCloudDocuments = iCloudDocumentsDirectory(create: false) {
        let iCloudInbox = iCloudDocuments
          .appendingPathComponent("YoursVault", isDirectory: true)
          .appendingPathComponent("inbox", isDirectory: true)
        candidates.append(contentsOf: try vaultInboxFiles(at: iCloudInbox).map { ($0, 0) })
      } else {
        unavailableSources.append("iCloud Drive")
      }
      if let localDocuments = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
        let localInbox = localDocuments
          .appendingPathComponent("YoursVault", isDirectory: true)
          .appendingPathComponent("inbox", isDirectory: true)
        candidates.append(contentsOf: try vaultInboxFiles(at: localInbox).map { ($0, 1) })
      }

      candidates.sort {
        $0.priority == $1.priority
          ? $0.url.lastPathComponent < $1.url.lastPathComponent
          : $0.priority < $1.priority
      }
      let byName = Dictionary(grouping: candidates, by: { $0.url.lastPathComponent })
      var conflictFiles: [String] = []
      for (name, namedCandidates) in byName {
        guard let first = namedCandidates.first else { continue }
        let allMatch = namedCandidates.dropFirst().allSatisfy { candidate in
          fileManager.contentsEqual(atPath: first.url.path, andPath: candidate.url.path)
        }
        if !allMatch {
          conflictFiles.append(name)
        }
      }
      conflictFiles.sort()
      let conflicted = Set(conflictFiles)
      let importable = candidates.filter { !conflicted.contains($0.url.lastPathComponent) }
      let byContent = Dictionary(grouping: importable) { candidate in
        (try? Data(contentsOf: candidate.url).base64EncodedString()) ?? candidate.url.path
      }

      var files: [String: [URL]] = [:]
      for duplicates in byContent.values {
        guard let selected = duplicates.first else { continue }
        let name = selected.url.lastPathComponent
        try fileManager.copyItem(at: selected.url, to: stagingInbox.appendingPathComponent(name))
        files[name] = duplicates.map { $0.url }
      }
      vaultInboxSessions[token] = VaultInboxSession(stagingDirectory: stagingDirectory, files: files)
      result([
        "token": token,
        "stagingPath": stagingDirectory.path,
        "scannedSources": ["iCloud Drive", "本机"],
        "unavailableSources": unavailableSources,
        "conflictFiles": conflictFiles
      ])
    } catch {
      try? fileManager.removeItem(at: stagingDirectory)
      result(FlutterError(code: "vault_inbox_prepare_failed", message: error.localizedDescription, details: nil))
    }
  }

  private func vaultInboxFiles(at inbox: URL) throws -> [URL] {
    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: inbox.path, isDirectory: &isDirectory), isDirectory.boolValue else {
      return []
    }
    return try FileManager.default.contentsOfDirectory(
      at: inbox,
      includingPropertiesForKeys: [.isRegularFileKey],
      options: [.skipsHiddenFiles]
    ).filter { file in
      file.pathExtension.lowercased() == "json" &&
        (file.lastPathComponent.hasSuffix(".plan.json") || file.lastPathComponent.hasSuffix(".exercise.json"))
    }
  }

  private func completeVaultInboxImport(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
          let token = arguments["token"] as? String,
          let session = vaultInboxSessions.removeValue(forKey: token) else {
      result(FlutterError(code: "vault_import_session_missing", message: "The selected Vault import session is no longer available", details: nil))
      return
    }
    let importedFiles = arguments["importedFiles"] as? [String] ?? []
    var failures: [String] = []
    defer {
      try? FileManager.default.removeItem(at: session.stagingDirectory)
    }

    for name in importedFiles {
      guard let sources = session.files[name] else { continue }
      for source in sources {
        do {
          let importedDirectory = source.deletingLastPathComponent()
            .appendingPathComponent("imported", isDirectory: true)
          try FileManager.default.createDirectory(at: importedDirectory, withIntermediateDirectories: true)
          var destination = importedDirectory.appendingPathComponent(name)
          if FileManager.default.fileExists(atPath: destination.path) {
            destination = importedDirectory.appendingPathComponent("\(Int(Date().timeIntervalSince1970 * 1000))-\(name)")
          }
          try FileManager.default.moveItem(at: source, to: destination)
        } catch {
          failures.append(name)
        }
      }
    }
    result(Array(Set(failures)).sorted())
  }

  private func copyPickedBackupToTemporaryDirectory(source: URL) throws -> URL {
    guard source.pathExtension.lowercased() == "zip" else {
      throw NSError(
        domain: "YoursFiles",
        code: 2,
        userInfo: [NSLocalizedDescriptionKey: text("invalid_backup_zip")]
      )
    }

    let folder = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
      .appendingPathComponent("YoursPickedBackups", isDirectory: true)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

    let timestamp = Int(Date().timeIntervalSince1970)
    let destination = folder.appendingPathComponent("icloud-yours-backup-\(timestamp).zip")
    if FileManager.default.fileExists(atPath: destination.path) {
      try FileManager.default.removeItem(at: destination)
    }
    try FileManager.default.copyItem(at: source, to: destination)
    return destination
  }

  func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    picker.dismiss(animated: true)
    guard let result = pendingPosterBackgroundPickResult else {
      return
    }
    pendingPosterBackgroundPickResult = nil
    guard let provider = results.first?.itemProvider else {
      result(nil)
      return
    }
    guard provider.canLoadObject(ofClass: UIImage.self) else {
      result(FlutterError(code: "photo_picker_unsupported", message: text("photo_picker_unsupported"), details: nil))
      return
    }
    provider.loadObject(ofClass: UIImage.self) { object, error in
      if let error = error {
        DispatchQueue.main.async {
          result(FlutterError(code: "photo_picker_failed", message: error.localizedDescription, details: nil))
        }
        return
      }
      guard let image = object as? UIImage, let data = image.jpegData(compressionQuality: 0.92) else {
        DispatchQueue.main.async {
          result(FlutterError(code: "photo_picker_failed", message: self.text("photo_picker_failed"), details: nil))
        }
        return
      }
      do {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("YoursPoster", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appendingPathComponent("poster-background-\(UUID().uuidString).jpg")
        try data.write(to: file, options: .atomic)
        DispatchQueue.main.async {
          result(file.path)
        }
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(code: "photo_picker_failed", message: error.localizedDescription, details: nil))
        }
      }
    }
  }
}
