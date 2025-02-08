// global_store.dart
import 'package:app/types.dart';
import 'package:flutter/material.dart';

class GlobalStore extends ChangeNotifier {
  int? _currentProjectId;
  String? _currentProjectName;
  int? _currentChatId;
  String? _currentChatName;
  String _model = 'gpt-4o-mini';
  String? selectedModel;
  List<Msg> messages = [];

  // Getters
  int? get currentProjectId => _currentProjectId;
  String? get currentProjectName => _currentProjectName;
  int? get currentChatId => _currentChatId;
  String? get currentChatName => _currentChatName;
  String get model => _model;

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

  void setSelectedModel(String model) {
    selectedModel = model;
    notifyListeners();
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
