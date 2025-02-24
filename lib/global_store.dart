import 'package:app/types.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import "package:collection/collection.dart";

class ChatTab {
  final int id;
  final String name;

  ChatTab({required this.id, required this.name});
}

class GlobalStore extends ChangeNotifier {
  // Static host configurations
  static final Map<String, Map<String, dynamic>> _hosts = {
    'OpenAI': {
      'url': 'https://api.openai.com/v1',
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
      'models': [
        "gemini-2.0-flash-lite-preview-02-05",
        "gemini-2.0-flash-001",
        "gemini-2.0-pro-exp-02-05",
        "gemini-2.0-flash-thinking-exp-01-21",
      ],
    },
  };

  // Model display names mapping
  static final Map<String, String> _modelDisplayNames = {
    // OpenAI models
    "o1": "o1",
    "o1-mini": "o1-mini",
    "o3-mini": "o3-mini",
    'gpt-4o': 'gpt-4o',
    'gpt-4o-mini': 'gpt-4o-mini',
    // Google models
    "gemini-2.0-flash-lite-preview-02-05":
        "gemini-2.0-flash-lite-preview-02-05",
    "gemini-2.0-flash-001": "gemini-2.0-flash-001",
    "gemini-2.0-pro-exp-02-05": "gemini-2.0-pro-exp-02-05",
    "gemini-2.0-flash-thinking-exp-01-21":
        "gemini-2.0-flash-thinking-exp-01-21",
  };

  int? _currentChatId;
  String? _currentChatName;
  String _model = 'gemini-2.0-flash-001';
  List<Msg> _messages = [];
  Status _status = Status.idle;
  List<ChatTab> tabs = [];

  // Cache for API keys
  String? _openaiApiKey;
  String? _geminiApiKey;

  // Getters
  int? get currentChatId => _currentChatId;
  String? get currentChatName => _currentChatName;
  String get model => _model;
  Status get status => _status;
  List<Msg> get messages => _messages;

  // Get the host information based on the selected model
  String get hostUrl {
    for (var host in _hosts.entries) {
      if (host.value['models'].contains(_model)) {
        return host.value['url'];
      }
    }
    throw Exception('No host found for model $_model');
  }

  Future<String> get apiKey async {
    for (var host in _hosts.entries) {
      if (host.value['models'].contains(_model)) {
        if (host.key == 'OpenAI') {
          if (_openaiApiKey == null) {
            final prefs = await SharedPreferences.getInstance();
            _openaiApiKey = prefs.getString('openai_api_key');
            if (_openaiApiKey == null || _openaiApiKey!.isEmpty) {
              throw Exception('OpenAI API key not found in settings');
            }
          }
          return _openaiApiKey!;
        } else if (host.key == 'Google') {
          if (_geminiApiKey == null) {
            final prefs = await SharedPreferences.getInstance();
            _geminiApiKey = prefs.getString('gemini_api_key');
            if (_geminiApiKey == null || _geminiApiKey!.isEmpty) {
              throw Exception('Gemini API key not found in settings');
            }
          }
          return _geminiApiKey!;
        }
      }
    }
    throw Exception('No API key found for model $_model');
  }

  // Get all available models with their display names
  List<Map<String, String>> get availableModels {
    List<Map<String, String>> models = [];
    for (var host in _hosts.entries) {
      for (var model in host.value['models']) {
        models.add({
          'id': model,
          'name': _modelDisplayNames[model] ?? model,
        });
      }
    }
    return models;
  }

  // Get the display name for the current model
  String get modelDisplayName => _modelDisplayNames[_model] ?? _model;

  void setStatus(Status newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  // Setters with notifyListeners()
  void setCurrentChat({required int id, required String name}) {
    _currentChatId = id;
    _currentChatName = name;
    notifyListeners();
  }

  void setModel(String newModel) {
    if (_hosts.values.any((host) => host['models'].contains(newModel))) {
      _model = newModel;
      notifyListeners();
    }
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  void setMessages(List<Msg> newMessages) {
    _messages = newMessages;
    notifyListeners();
  }

  void Function(String a) addMessage(Msg msg) {
    _messages.add(msg);
    notifyListeners();

    return (String chunk) {
      // print(chunk);
      msg.content += chunk;
      notifyListeners();
    };
  }

  void addTab({required int id, required String name}) {
    // Check if tab with this id already exists
    final existingIndex = tabs.indexWhere((tab) => tab.id == id);
    if (existingIndex != -1) {
      // Update existing tab if name is different
      if (tabs[existingIndex].name != name) {
        tabs[existingIndex] = ChatTab(id: id, name: name);
        notifyListeners();
      }
    } else {
      // Add new tab
      tabs.add(ChatTab(id: id, name: name));
      notifyListeners();
    }
  }

  void removeTab(int id) {
    final wasCurrentTab = id == _currentChatId;
    tabs.removeWhere((tab) => tab.id == id);

    if (wasCurrentTab && tabs.isNotEmpty) {
      // Set the next available tab as current
      final nextTab = tabs[0]; // Take the first tab
      setCurrentChat(id: nextTab.id, name: nextTab.name);
    } else if (wasCurrentTab) {
      // If no tabs left, clear current chat
      _currentChatId = null;
      _currentChatName = null;
    }

    notifyListeners();
  }
}
