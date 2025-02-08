import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:app/types.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AIService {
  final String _apiKey = Platform.environment['OPENAI_API_KEY'] ?? '';

  Stream<String> generateText({
    required List<Msg> messages,
    required String model,
  }) async* {
    final request = http.Request(
        'POST', Uri.parse("https://api.openai.com/v1/chat/completions"))
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      })
      ..body = jsonEncode({
        'model': model,
        'messages': [
          ...messages.map((msg) => {
                "role": msg.role.name,
                "content": msg.content,
              }),
        ],
        'temperature': 1,
        'top_p': 1,
        'stream': true,
      });

    final response = await http.Client().send(request);

    if (response.statusCode == 200) {
      final utf8Decoder = Utf8Decoder();
      await for (var chunk in response.stream
          .transform(utf8.decoder)
          .transform(LineSplitter())) {
        if (chunk.isNotEmpty) {
          try {
            final json = jsonDecode(chunk.replaceAll('data: ', ''));
            if (json.containsKey('choices')) {
              final content = json['choices'][0]['delta']['content'];
              if (content != null) {
                yield content; // Emit the content chunk
              }
            }
          } catch (e) {
            // Handle invalid JSON or end of stream marker
            if (chunk.trim() != '[DONE]') {
              debugPrint('Error decoding chunk: $chunk');
            }
          }
        }
      }
    } else {
      final responseText = await response.stream.transform(utf8.decoder).join();
      throw Exception(
          'API request failed with status ${response.statusCode}: $responseText');
    }
  }
}
