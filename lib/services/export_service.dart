import 'dart:typed_data';

import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:screenshot/screenshot.dart';

class ExportService {
  final ScreenshotController _controller = ScreenshotController();

  Future<Uint8List> captureWidgetToPng(Function builder) async {
    final bytes = await _controller.captureFromWidget(builder());
    return bytes;
  }

  Future<void> savePngToGallery(Uint8List bytes, {String name = 'map_scene'}) async {
    await ImageGallerySaver.saveImage(bytes, name: name);
  }
}
