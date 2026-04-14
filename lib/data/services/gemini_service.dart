import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  static Future<String?> callGeminiApi(
    String input,
    Map<String, dynamic> settings, {
    Uint8List? imageBytes,
    String mimeType = 'image/jpeg',
  }) async {
    final apiKey = settings['key']?.toString();
    final modelId = settings['model']?.toString();
    const contentApi = 'generateContent';

    if (apiKey == null || modelId == null) {
      debugPrint('[GEMINI] Error: key or model is missing in settings');
      return null;
    }

    debugPrint("[GEMINI] key : $apiKey");
    final instructions = settings['instructions'];
    final sysInstr = instructions is List
        ? instructions.join(', ')
        : (instructions ?? '');

    final parts = <Map<String, dynamic>>[
      {'text': 'SYSTEM_INSTRUCTION: $sysInstr\nUSER_INPUT: $input'},
    ];

    if (imageBytes != null && imageBytes.isNotEmpty) {
      try {
        final base64Image = base64Encode(imageBytes);
        parts.add({
          'inline_data': {'mime_type': mimeType, 'data': base64Image},
        });
      } catch (e) {
        debugPrint('[GEMINI] Image encode error: $e');
      }
    }

    final body = {
      'contents': [
        {'role': 'user', 'parts': parts},
      ],
      'generationConfig': {'responseMimeType': 'text/plain'},
    };

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$modelId:$contentApi?key=$apiKey',
    );

    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (res.statusCode != 200) {
        debugPrint('[GEMINI] API Error: ${res.statusCode} | ${res.body}');
        if (res.statusCode == 429) return "ERROR_LIMIT_REACHED";
        return null;
      }

      final jsonRes = jsonDecode(res.body);
      final textResult =
          jsonRes['candidates']?[0]['content']['parts']?[0]['text'];
      return textResult;
    } catch (e) {
      debugPrint('[GEMINI] HTTP Exception: $e');
      return null;
    }
  }
}
