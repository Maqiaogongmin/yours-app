import 'package:flutter/services.dart';

class YoursSharePlatform {
  YoursSharePlatform({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('yours/photos');

  final MethodChannel _channel;

  Future<String?> pickPosterBackground() {
    return _channel.invokeMethod<String>('pickPosterBackground');
  }

  Future<void> savePosterToPhotos(Uint8List pngBytes) async {
    await _channel.invokeMethod<bool>('saveImageToPhotos', {'bytes': pngBytes});
  }
}
