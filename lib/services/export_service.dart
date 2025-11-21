import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:screenshot/screenshot.dart';

class ExportService {
  final ScreenshotController _controller = ScreenshotController();

  Future<Uint8List> captureWidgetToPng(Widget widget, {double pixelRatio = 2.0}) async {
    final bytes = await _controller.captureFromWidget(
      MaterialApp(home: widget),
      pixelRatio: pixelRatio,
    );
    return bytes;
  }

  Future<void> savePngToGallery(Uint8List bytes, {String name = 'map_scene'}) async {
    await ImageGallerySaver.saveImage(bytes, name: name);
  }
}
