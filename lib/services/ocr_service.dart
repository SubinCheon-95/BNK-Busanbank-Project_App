import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.korean,  // 한글 인식
  );

  // 이미지에서 텍스트 추출
  Future<String> extractText(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      // 모든 텍스트 블록 결합
      final textBuffer = StringBuffer();
      for (final block in recognizedText.blocks) {
        textBuffer.writeln(block.text);
      }

      return textBuffer.toString().trim();
    } catch (e) {
      print('❌ OCR 에러: $e');
      throw Exception('텍스트 추출 실패: $e');
    }
  }

  // 리소스 해제
  void dispose() {
    _textRecognizer.close();
  }
}