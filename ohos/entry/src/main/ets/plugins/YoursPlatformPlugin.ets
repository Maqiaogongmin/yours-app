import { common, Want } from '@kit.AbilityKit';
import { fileIo, fileUri, picker } from '@kit.CoreFileKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';

interface VaultInboxCandidate {
  path: string;
  priority: number;
}

interface VaultInboxSession {
  stagingDirectory: string;
  files: Map<string, string[]>;
}

export default class YoursPlatformPlugin implements FlutterPlugin, MethodCallHandler {
  private photosChannel: MethodChannel | null = null;
  private filesChannel: MethodChannel | null = null;
  private context: common.UIAbilityContext | null = null;
  private vaultInboxSessions: Map<string, VaultInboxSession> = new Map();

  constructor(context?: common.UIAbilityContext) {
    if (context !== undefined) {
      this.context = context;
    }
  }

  getUniqueClassName(): string {
    return 'YoursPlatformPlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    if (this.context === null) {
      this.context = binding.getApplicationContext() as common.UIAbilityContext;
    }
    this.photosChannel = new MethodChannel(binding.getBinaryMessenger(), 'yours/photos');
    this.filesChannel = new MethodChannel(binding.getBinaryMessenger(), 'yours/files');
    this.photosChannel.setMethodCallHandler(this);
    this.filesChannel.setMethodCallHandler(this);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.photosChannel !== null) {
      this.photosChannel.setMethodCallHandler(null);
    }
    if (this.filesChannel !== null) {
      this.filesChannel.setMethodCallHandler(null);
    }
    this.photosChannel = null;
    this.filesChannel = null;
    this.context = null;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    if (call.method === 'pickPosterBackground') {
      this.pickPosterBackground(result);
      return;
    }
    if (call.method === 'saveImageToPhotos') {
      this.saveImageToPhotos(call, result);
      return;
    }
    if (call.method === 'syncVaultToPublicDocuments') {
      this.syncVaultToPublicDocuments(call, result);
      return;
    }
    if (call.method === 'prepareDefaultVaultInboxImport') {
      this.prepareDefaultVaultInboxImport(result);
      return;
    }
    if (call.method === 'completeVaultInboxImport') {
      this.completeVaultInboxImport(call, result);
      return;
    }
    if (call.method === 'pickPublicBackup') {
      this.pickPublicBackup(result);
      return;
    }
    if (call.method === 'importPublicBackup') {
      this.importPublicBackup(result);
      return;
    }
    if (call.method === 'openExternalUrl') {
      this.openExternalUrl(call, result);
      return;
    }
    result.notImplemented();
  }

  private async pickPosterBackground(result: MethodResult): Promise<void> {
    try {
      const imagePath = await this.pickPhotoIntoSandbox();
      result.success(imagePath);
    } catch (error) {
      result.error('pickPosterBackgroundFailed', this.errorMessage(error), null);
    }
  }

  private async saveImageToPhotos(call: MethodCall, result: MethodResult): Promise<void> {
    try {
      const context = this.requireContext();
      const bytes = this.argumentAsArrayBuffer(call, 'bytes');
      const imagePath = this.writeBytesToSandbox(context, bytes, `yours-share-poster-${Date.now()}.png`);
      try {
        await this.saveSandboxImageToPhotos(context, imagePath);
      } finally {
        this.deleteQuietly(imagePath);
      }
      result.success(true);
    } catch (error) {
      result.error('saveImageToPhotosFailed', this.errorMessage(error), null);
    }
  }

  private async syncVaultToPublicDocuments(call: MethodCall, result: MethodResult): Promise<void> {
    try {
      const vaultPath = this.argumentAsString(call, 'path');
      const sourceRoot = this.parentDirectory(vaultPath);
      const downloadPath = await this.pickDownloadDirectoryPath();
      this.ensureDirectory(downloadPath);
      await this.syncDocumentsRootToVisibleDirectory(sourceRoot, downloadPath);

      result.success(0);
    } catch (error) {
      result.error('syncVaultToPublicDocumentsFailed', this.errorMessage(error), null);
    }
  }

  private async prepareDefaultVaultInboxImport(result: MethodResult): Promise<void> {
    const token = `${Date.now()}-${Math.floor(Math.random() * 1000000)}`;
    const stagingDirectory = `${this.requireContext().cacheDir}/YoursVaultImports/${token}`;
    const stagingInbox = `${stagingDirectory}/inbox`;
    try {
      this.ensureDirectory(stagingInbox);
      const candidates = this.findDownloadVaultInboxFiles();
      const groupedByName = new Map<string, VaultInboxCandidate[]>();
      for (const candidate of candidates) {
        const name = this.fileName(candidate.path);
        const group = groupedByName.get(name) ?? [];
        group.push(candidate);
        groupedByName.set(name, group);
      }

      const conflictFiles: string[] = [];
      const importable: VaultInboxCandidate[] = [];
      for (const name of groupedByName.keys()) {
        const namedCandidates = groupedByName.get(name) ?? [];
        const expected = fileIo.readTextSync(namedCandidates[0].path);
        const allMatch = namedCandidates.every((candidate: VaultInboxCandidate) =>
          fileIo.readTextSync(candidate.path) === expected,
        );
        if (!allMatch) {
          conflictFiles.push(name);
          continue;
        }
        importable.push(...namedCandidates);
      }
      conflictFiles.sort();

      const byContent = new Map<string, VaultInboxCandidate[]>();
      for (const candidate of importable) {
        const content = fileIo.readTextSync(candidate.path);
        const duplicates = byContent.get(content) ?? [];
        duplicates.push(candidate);
        byContent.set(content, duplicates);
      }

      const files = new Map<string, string[]>();
      for (const duplicates of byContent.values()) {
        duplicates.sort((left: VaultInboxCandidate, right: VaultInboxCandidate) =>
          left.priority === right.priority ? left.path.localeCompare(right.path) : left.priority - right.priority,
        );
        const selected = duplicates[0];
        const name = this.fileName(selected.path);
        await this.copyFileToCreatedTarget(selected.path, `${stagingInbox}/${name}`);
        files.set(name, duplicates.map((candidate: VaultInboxCandidate) => candidate.path));
      }

      this.vaultInboxSessions.set(token, { stagingDirectory, files });
      result.success({
        'token': token,
        'stagingPath': stagingDirectory,
        'scannedSources': ['Download/有思/YoursVault'],
        'unavailableSources': [],
        'conflictFiles': conflictFiles,
      });
    } catch (error) {
      this.deleteDirectoryRecursively(stagingDirectory);
      result.error('vaultInboxPrepareFailed', this.errorMessage(error), null);
    }
  }

  private async completeVaultInboxImport(call: MethodCall, result: MethodResult): Promise<void> {
    const token: string = call.argument('token') as string;
    const session = this.vaultInboxSessions.get(token);
    if (typeof token !== 'string' || session === undefined) {
      result.error(
        'vaultImportSessionMissing',
        'The selected Vault import session is no longer available',
        null,
      );
      return;
    }
    this.vaultInboxSessions.delete(token);
    const importedFiles: string[] = (call.argument('importedFiles') as string[]) ?? [];
    const failures: string[] = [];
    try {
      for (const name of importedFiles) {
        const sources = session.files.get(name) ?? [];
        for (const source of sources) {
          try {
            await this.archiveVaultInboxFile(source);
          } catch (_) {
            failures.push(name);
          }
        }
      }
      result.success(Array.from(new Set(failures)).sort());
    } finally {
      this.deleteDirectoryRecursively(session.stagingDirectory);
    }
  }

  private findDownloadVaultInboxFiles(): VaultInboxCandidate[] {
    const inboxes = [
      '/storage/Users/currentUser/Download/有思/YoursVault/inbox',
      '/storage/Users/currentUser/Download/com.ly.yours/YoursVault/inbox',
      '/storage/Users/currentUser/Download/YoursVault/inbox',
    ];
    const candidates: VaultInboxCandidate[] = [];
    for (let priority = 0; priority < inboxes.length; priority += 1) {
      const inbox = inboxes[priority];
      if (!this.pathExists(inbox) || !fileIo.statSync(inbox).isDirectory()) {
        continue;
      }
      for (const name of fileIo.listFileSync(inbox).sort()) {
        const path = `${inbox}/${name}`;
        if (this.isVaultInboxImportFile(name) && fileIo.statSync(path).isFile()) {
          candidates.push({ path, priority });
        }
      }
    }
    return candidates;
  }

  private isVaultInboxImportFile(name: string): boolean {
    const normalized = name.toLowerCase();
    return normalized.endsWith('.plan.json') || normalized.endsWith('.exercise.json');
  }

  private async archiveVaultInboxFile(source: string): Promise<void> {
    const inbox = this.parentDirectory(source);
    const imported = `${inbox}/imported`;
    this.ensureDirectory(imported);
    const name = this.fileName(source);
    let destination = `${imported}/${name}`;
    if (this.pathExists(destination)) {
      destination = `${imported}/${Date.now()}-${name}`;
    }
    await this.copyFileToCreatedTarget(source, destination);
    fileIo.unlinkSync(source);
  }

  private async pickPublicBackup(result: MethodResult): Promise<void> {
    try {
      const backupPath = await this.pickBackupIntoSandbox();
      result.success(backupPath);
    } catch (error) {
      result.error('pickPublicBackupFailed', this.errorMessage(error), null);
    }
  }

  private async importPublicBackup(result: MethodResult): Promise<void> {
    try {
      const backupPath = await this.importDefaultVisibleBackup();
      result.success(backupPath);
    } catch (error) {
      result.error('importPublicBackupFailed', this.errorMessage(error), null);
    }
  }

  private async openExternalUrl(call: MethodCall, result: MethodResult): Promise<void> {
    try {
      const url = this.argumentAsString(call, 'url');
      this.ensureWebUrl(url);
      await this.openWebUrl(url);
      result.success(true);
    } catch (error) {
      result.error('openExternalUrlFailed', this.errorMessage(error), null);
    }
  }

  private async openWebUrl(url: string): Promise<void> {
    const context = this.requireContext();
    try {
      await context.openLink(url);
      return;
    } catch (_) {
    }
    const want: Want = {
      action: 'ohos.want.action.viewData',
      entities: ['entity.system.browsable'],
      uri: url,
    };
    await context.startAbility(want);
  }

  private async pickPhotoIntoSandbox(): Promise<string | null> {
    const selectOptions = new photoAccessHelper.PhotoSelectOptions();
    selectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    selectOptions.maxSelectNumber = 1;
    const photoPicker = new photoAccessHelper.PhotoViewPicker();
    const selectResult = await photoPicker.select(selectOptions);
    if (selectResult.photoUris.length === 0 || selectResult.photoUris[0].trim().length === 0) {
      return null;
    }
    const targetPath = `${this.posterBackgroundDirectory()}/poster-background-${Date.now()}.jpg`;
    await this.copyFileToCreatedTarget(selectResult.photoUris[0], targetPath);
    this.ensureNonEmptyFile(targetPath);
    return targetPath;
  }

  private requireContext(): common.UIAbilityContext {
    if (this.context === null) {
      throw new Error('UIAbilityContext is not attached.');
    }
    return this.context;
  }

  private writeBytesToSandbox(context: common.UIAbilityContext, bytes: ArrayBuffer, name: string): string {
    const path = `${context.filesDir}/${name}`;
    const file = fileIo.openSync(
      path,
      fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC,
    );
    try {
      fileIo.writeSync(file.fd, bytes);
    } finally {
      fileIo.closeSync(file);
    }
    return path;
  }

  private async saveSandboxImageToPhotos(context: common.UIAbilityContext, path: string): Promise<void> {
    const helper = photoAccessHelper.getPhotoAccessHelper(context);
    const destinationUris = await helper.showAssetsCreationDialog(
      [path],
      [{
        title: `yours-share-poster-${Date.now()}`,
        fileNameExtension: 'png',
        photoType: photoAccessHelper.PhotoType.IMAGE,
        subtype: photoAccessHelper.PhotoSubtype.DEFAULT,
      }],
    );
    if (destinationUris.length === 0 || destinationUris[0].trim().length === 0) {
      throw new Error('No destination photo uri returned.');
    }
    await this.copyFile(path, destinationUris[0]);
  }

  private async copyFile(sourcePath: string, destinationUri: string): Promise<void> {
    const sourceFile = await fileIo.open(sourcePath, fileIo.OpenMode.READ_ONLY);
    const destinationFile = await fileIo.open(destinationUri, fileIo.OpenMode.WRITE_ONLY);
    try {
      await fileIo.copyFile(sourceFile.fd, destinationFile.fd);
    } finally {
      fileIo.closeSync(sourceFile);
      fileIo.closeSync(destinationFile);
    }
  }

  private async pickDownloadDirectoryPath(): Promise<string> {
    const context = this.requireContext();
    const saveOptions = new picker.DocumentSaveOptions();
    saveOptions.pickerMode = picker.DocumentPickerMode.DOWNLOAD;
    const documentPicker = new picker.DocumentViewPicker(context);
    const destinationUris = await documentPicker.save(saveOptions);
    if (destinationUris.length === 0 || destinationUris[0].trim().length === 0) {
      throw new Error('No Download directory uri returned.');
    }
    return this.downloadDirectoryPath(destinationUris[0]);
  }

  private async pickBackupIntoSandbox(): Promise<string | null> {
    const context = this.requireContext();
    const selectOptions = new picker.DocumentSelectOptions();
    const documentPicker = new picker.DocumentViewPicker(context);
    const selectedUris = await documentPicker.select(selectOptions);
    if (selectedUris.length === 0 || selectedUris[0].trim().length === 0) {
      return null;
    }
    const targetPath = `${this.backupImportDirectory()}/picked-yours-backup.zip`;
    await this.copyFileToCreatedTarget(selectedUris[0], targetPath);
    this.ensureZipFile(targetPath);
    return targetPath;
  }

  private async importDefaultVisibleBackup(): Promise<string | null> {
    const candidates = [
      '/storage/Users/currentUser/Download/com.ly.yours/yours-backup.zip',
      '/storage/Users/currentUser/Download/有思/yours-backup.zip',
      '/storage/Users/currentUser/Documents/com.ly.yours/yours-backup.zip',
      '/storage/Users/currentUser/Documents/有思/yours-backup.zip',
      '/data/local/tmp/yours-backup.zip',
    ];
    for (const candidate of candidates) {
      if (!this.pathExists(candidate) || !fileIo.statSync(candidate).isFile()) {
        continue;
      }
      const targetPath = `${this.backupImportDirectory()}/visible-yours-backup.zip`;
      await this.copyFileToCreatedTarget(candidate, targetPath);
      this.ensureZipFile(targetPath);
      return targetPath;
    }
    return null;
  }

  private async copyFileToCreatedTarget(sourcePath: string, destinationPathOrUri: string): Promise<void> {
    this.deleteExistingFile(destinationPathOrUri);
    const sourceFile = await fileIo.open(sourcePath, fileIo.OpenMode.READ_ONLY);
    const destinationFile = await fileIo.open(
      destinationPathOrUri,
      fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC,
    );
    try {
      await fileIo.copyFile(sourceFile.fd, destinationFile.fd);
    } finally {
      fileIo.closeSync(sourceFile);
      fileIo.closeSync(destinationFile);
    }
  }

  private backupImportDirectory(): string {
    const context = this.requireContext();
    const directory = `${context.filesDir}/backup_imports`;
    this.ensureDirectory(directory);
    return directory;
  }

  private posterBackgroundDirectory(): string {
    const context = this.requireContext();
    const directory = `${context.filesDir}/poster_backgrounds`;
    this.ensureDirectory(directory);
    return directory;
  }

  private ensureZipFile(path: string): void {
    const file = fileIo.openSync(path, fileIo.OpenMode.READ_ONLY);
    const buffer = new ArrayBuffer(4);
    try {
      const readLength = fileIo.readSync(file.fd, buffer);
      if (readLength < 4) {
        throw new Error('Selected backup is too small.');
      }
      const bytes = new Uint8Array(buffer);
      if (bytes[0] !== 0x50 || bytes[1] !== 0x4B) {
        throw new Error('Selected file is not a ZIP backup.');
      }
    } finally {
      fileIo.closeSync(file);
    }
  }

  private ensureNonEmptyFile(path: string): void {
    if (!this.pathExists(path) || !fileIo.statSync(path).isFile()) {
      throw new Error(`${path} does not exist.`);
    }
    if (fileIo.statSync(path).size <= 0) {
      throw new Error(`${path} is empty.`);
    }
  }

  private async copyFileFamily(sourceRoot: string, destinationRoot: string, baseName: string): Promise<void> {
    for (const name of [baseName, `${baseName}-wal`, `${baseName}-shm`]) {
      const sourcePath = `${sourceRoot}/${name}`;
      if (!this.pathExists(sourcePath)) {
        continue;
      }
      await this.copyFileToCreatedTarget(sourcePath, `${destinationRoot}/${name}`);
    }
  }

  private async syncDocumentsRootToVisibleDirectory(sourceRoot: string, destinationRoot: string): Promise<void> {
    await this.copyFileFamily(sourceRoot, destinationRoot, 'local_training.sqlite');
    await this.copyFileFamily(sourceRoot, destinationRoot, 'custom_exercises.sqlite');
    await this.copyDirectoryIfExists(`${sourceRoot}/YoursVault`, `${destinationRoot}/YoursVault`);
    await this.copyDirectoryIfExists(`${sourceRoot}/backups`, `${destinationRoot}/backups`);
    await this.copyDirectoryIfExists(`${sourceRoot}/exercise_images`, `${destinationRoot}/exercise_images`);
  }

  private async copyDirectoryIfExists(sourceDirectory: string, destinationDirectory: string): Promise<void> {
    if (!this.pathExists(sourceDirectory) || !fileIo.statSync(sourceDirectory).isDirectory()) {
      return;
    }
    this.ensureDirectory(destinationDirectory);
    const names = fileIo.listFileSync(sourceDirectory);
    for (const name of names) {
      const sourcePath = `${sourceDirectory}/${name}`;
      const destinationPath = `${destinationDirectory}/${name}`;
      const stat = fileIo.statSync(sourcePath);
      if (stat.isDirectory()) {
        await this.copyDirectoryIfExists(sourcePath, destinationPath);
      } else if (stat.isFile()) {
        await this.copyFileToCreatedTarget(sourcePath, destinationPath);
      }
    }
  }

  private parentDirectory(path: string): string {
    const normalized = path.endsWith('/') ? path.slice(0, path.length - 1) : path;
    const index = normalized.lastIndexOf('/');
    if (index <= 0) {
      throw new Error(`Cannot resolve parent directory for ${path}.`);
    }
    return normalized.slice(0, index);
  }

  private fileName(path: string): string {
    const normalized = path.endsWith('/') ? path.slice(0, path.length - 1) : path;
    const index = normalized.lastIndexOf('/');
    return index < 0 ? normalized : normalized.slice(index + 1);
  }

  private pathExists(path: string): boolean {
    try {
      fileIo.statSync(path);
      return true;
    } catch (_) {
      return false;
    }
  }

  private ensureDirectory(path: string): void {
    if (this.pathExists(path)) {
      if (!fileIo.statSync(path).isDirectory()) {
        throw new Error(`${path} exists but is not a directory.`);
      }
      return;
    }
    fileIo.mkdirSync(path, true);
  }

  private deleteExistingFile(path: string): void {
    if (!this.pathExists(path)) {
      return;
    }
    if (!fileIo.statSync(path).isFile()) {
      throw new Error(`${path} exists but is not a file.`);
    }
    fileIo.unlinkSync(path);
  }

  private deleteDirectoryRecursively(path: string): void {
    if (!this.pathExists(path)) {
      return;
    }
    const stat = fileIo.statSync(path);
    if (stat.isFile()) {
      fileIo.unlinkSync(path);
      return;
    }
    for (const name of fileIo.listFileSync(path)) {
      this.deleteDirectoryRecursively(`${path}/${name}`);
    }
    fileIo.rmdirSync(path);
  }

  private downloadDirectoryPath(downloadUri: string): string {
    const uriObject = new fileUri.FileUri(downloadUri);
    const directoryPath = uriObject.path;
    if (directoryPath.trim().length === 0) {
      throw new Error(`Download directory path is empty for ${downloadUri}.`);
    }
    return directoryPath.endsWith('/') ? directoryPath.slice(0, directoryPath.length - 1) : directoryPath;
  }

  private argumentAsString(call: MethodCall, key: string): string {
    const value: string = call.argument(key) as string;
    if (typeof value !== 'string' || value.trim().length === 0) {
      throw new Error(`Missing string argument: ${key}`);
    }
    return value;
  }

  private ensureWebUrl(url: string): void {
    if (!url.startsWith('https://') && !url.startsWith('http://')) {
      throw new Error(`Unsupported URL scheme: ${url}`);
    }
  }

  private argumentAsArrayBuffer(call: MethodCall, key: string): ArrayBuffer {
    const value: Object = call.argument(key) as Object;
    if (value instanceof ArrayBuffer) {
      return value;
    }
    if (value instanceof Uint8Array) {
      return value.buffer.slice(value.byteOffset, value.byteOffset + value.byteLength);
    }
    throw new Error(`Missing bytes argument: ${key}`);
  }

  private deleteQuietly(path: string): void {
    try {
      fileIo.unlinkSync(path);
    } catch (_) {
    }
  }

  private errorMessage(error: Object): string {
    if (error instanceof Error && error.message.length > 0) {
      return error.message;
    }
    return `${error}`;
  }
}
