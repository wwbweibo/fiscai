import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'dart:developer';

class OCRService {
  static Future<String> ocrImage(String imagePath) async {
    try {
      String text = await FlutterTesseractOcr.extractText(
        imagePath, 
        language: 'chi_sim+eng',
        args: {
          "psm": "4",
          "preserve_interword_spaces": "1",
        }
      );
      log('OCRing image: $text');
      return text;
    } catch (e) {
      print('Error OCRing image: $e');
      log('Error OCRing image: $e');
      return 'OCRing image failed';
    }
  }
}
