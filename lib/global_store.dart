// global_store.dart
import 'package:app/types.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class GlobalStore extends ChangeNotifier {
  // Static host configurations
  static final Map<String, Map<String, dynamic>> hosts = {
    'OpenAI': {
      'url': 'https://api.openai.com/v1',
      'apiKey': () {
        final key = Platform.environment['OPENAI_API_KEY'];
        if (key == null || key.isEmpty) {
          throw Exception('OPENAI_API_KEY environment variable not found');
        }
        return key;
      }(),
      'models': [
        "o1",
        "o1-mini",
        "o3-mini",
        'gpt-4o',
        'gpt-4o-mini',
      ],
    },
    'Google': {
      'url': 'https://generativelanguage.googleapis.com/v1beta',
      'apiKey': () {
        final key = Platform.environment['GEMINI_API_KEY'];
        if (key == null || key.isEmpty) {
          throw Exception('GEMINI_API_KEY environment variable not found');
        }
        return key;
      }(),
      'models': [
        "gemini-2.0-flash-lite-preview-02-05",
        "gemini-2.0-flash-001",
        "gemini-2.0-pro-exp-02-05",
        "gemini-2.0-flash-thinking-exp-01-21",
      ],
    },
  };

  int? _currentProjectId;
  String? _currentProjectName;
  int? _currentChatId;
  String? _currentChatName;
  String _hostKey = 'Google';
  String _model = 'gemini-2.0-flash-001';
  List<Msg> messages = [];

  // Getters
  int? get currentProjectId => _currentProjectId;
  String? get currentProjectName => _currentProjectName;
  int? get currentChatId => _currentChatId;
  String? get currentChatName => _currentChatName;
  String get model => _model;
  String get hostKey => _hostKey;
  String get hostUrl => hosts[_hostKey]?['url'] ?? '';
  String get apiKey => hosts[_hostKey]?['apiKey'] ?? '';
  List<String> get availableModels =>
      (hosts[_hostKey]?['models'] as List<String>?) ?? [];

  // Setters with notifyListeners()
  void setCurrentProject({required int id, required String name}) {
    _currentProjectId = id;
    _currentProjectName = name;
    notifyListeners();
  }

  void setCurrentChat({required int id, required String name}) {
    _currentChatId = id;
    _currentChatName = name;
    notifyListeners();
  }

  void setModel(String newModel) {
    _model = newModel;
    notifyListeners();
  }

  void setHost(String newHostKey) {
    if (hosts.containsKey(newHostKey)) {
      _hostKey = newHostKey;
      // Reset model to first available one for new host
      _model = (hosts[newHostKey]?['models'] as List<String>).first;
      notifyListeners();
    }
  }

  void addMessage(Msg message) {
    messages.add(message);
    notifyListeners();
  }

  void clearMessages() {
    messages.clear();
    notifyListeners();
  }

  void setMessages(List<Msg> newMessages) {
    messages = newMessages;
    notifyListeners();
  }

  void updateLastBotMsg(String content) {
    if (messages.isNotEmpty && messages.last.role == MsgRole.assistant) {
      messages.last.content = content;
      notifyListeners();
    }
  }
}
