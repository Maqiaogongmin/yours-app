import Flutter
import PhotosUI
import UIKit
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, UIDocumentPickerDelegate, PHPickerViewControllerDelegate {
  private let iCloudContainerIdentifier = "iCloud.com.ly.yours"
  private var pendingICloudBackupPickResult: FlutterResult?
  private var pendingPosterBackgroundPickResult: FlutterResult?

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
    if FileManager.default.fileExists(atPath: destination.path) {
      try FileManager.default.removeItem(at: destination)
    }
    try FileManager.default.copyItem(at: source, to: destination)
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
