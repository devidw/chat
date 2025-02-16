import 'dart:convert';
import 'dart:async';
import 'package:app/types.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AIService {
  StreamController<String>? _currentController;
  bool _isCancelled = false;

  void cancelGeneration() {
    _isCancelled = true;
    _currentController?.close();
    _currentController = null;
  }

  Stream<String> generateText({
    required List<Msg> messages,
    required String model,
    required String hostUrl,
    required String apiKey,
  }) async* {
    _isCancelled = false;
    _currentController = StreamController<String>();

    final isGoogle = hostUrl.contains('googleapis');

    Map<String, dynamic> body;
    String endpoint;

    if (isGoogle) {
      body = {
        'contents': [
          {
            'parts': messages
                .map((msg) => {
                      'text': msg.content,
                    })
                .toList(),
          }
        ]
      };
      endpoint =
          '$hostUrl/models/$model:streamGenerateContent?alt=sse&key=$apiKey';
    } else {
      body = {
        'stream': true,
        'model': model,
        'messages': messages
            .map((msg) => {
                  'role': msg.role.name,
                  'content': msg.content,
                })
            .toList(),
      };
      endpoint = '$hostUrl/chat/completions';
    }

    debugPrint(endpoint);

    final request = http.Request('POST', Uri.parse(endpoint))
      ..headers.addAll({
        'Content-Type': 'application/json',
        if (!isGoogle) 'Authorization': 'Bearer $apiKey',
      })
      ..body = jsonEncode(body);

    final client = http.Client();
    try {
      final response = await client.send(request);

      if (response.statusCode == 200) {
        await for (var chunk in response.stream
            .transform(utf8.decoder)
            .transform(LineSplitter())) {
          if (_isCancelled) {
            client.close();
            break;
          }

          if (chunk.isNotEmpty) {
            try {
              if (isGoogle) {
                if (!chunk.startsWith('data: ')) continue;

                final json = jsonDecode(chunk.substring(6));
                if (!json.containsKey('candidates')) continue;

                final content = json['candidates'][0]['content']['parts'][0]
                    ['text'] as String?;
                if (content != null) {
                  yield content;
                }
              } else {
                final json = jsonDecode(chunk.replaceAll('data: ', ''));
                if (json.containsKey('choices')) {
                  final content = json['choices'][0]['delta']['content'];
                  if (content != null) {
                    yield content;
                  }
                }
              }
            } catch (e) {
              if (chunk.trim() != '[DONE]') {
                debugPrint('Error decoding chunk: $chunk');
              }
            }
          }
        }
      } else {
        final responseText =
            await response.stream.transform(utf8.decoder).join();
        throw Exception(
            'API request failed with status ${response.statusCode}: $responseText');
      }
    } finally {
      client.close();
      _currentController?.close();
      _currentController = null;
    }
  }
}
