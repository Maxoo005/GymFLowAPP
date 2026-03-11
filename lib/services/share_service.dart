import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  ShareService._();

  /// Przechwytuje widget z otoczki [RepaintBoundary] i wywołuje okno udostępniania
  static Future<void> shareWidget(GlobalKey key, String fileName) async {
    try {
      // 1. Odszukaj RenderRepaintBoundary dla danego klucza
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Nie znaleziono RenderRepaintBoundary dla tego klucza. Upewnij się, że widget został poprawnie narysowany.');
      }

      // 2. Skonwertuj do obrazu w wysokiej rozdzielczości (pixelRatio)
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();

      if (pngBytes == null) {
        throw Exception('Błąd podczas generowania obrazu PNG.');
      }

      // 3. Zapisz plik w katalogu tymczasowym
      final directory = await getTemporaryDirectory();
      final File imgFile = File('${directory.path}/$fileName.png');
      await imgFile.writeAsBytes(pngBytes);

      // 4. Udostępnij za pomocą share_plus
      final xFile = XFile(imgFile.path, mimeType: 'image/png');
      await Share.shareXFiles([xFile], text: 'Zobacz mój progres na GymLoom! 💪');
    } catch (e) {
      debugPrint('Błąd udostępniania widgetu: $e');
      rethrow;
    }
  }
}
