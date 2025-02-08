import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../global_store.dart';
import '../db.dart';
import '../styles.dart';

class ChatControls extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  const ChatControls({
    super.key,
    required this.controller,
    required this.focusNode,
  });

  Future<void> _clearChatHistory(BuildContext context) async {
    final globalStore = Provider.of<GlobalStore>(context, listen: false);
    if (globalStore.currentChatId == null) return;

    // Delete messages from database
    final messages =
        await DATA.listMessagesByChat(chatId: globalStore.currentChatId!);
    for (var message in messages) {
      await DATA.deleteMessage(id: message['id']);
    }

    // Clear messages from store
    globalStore.clearMessages();
  }

  Future<void> _redoLast(BuildContext context) async {
    final globalStore = Provider.of<GlobalStore>(context, listen: false);
    if (globalStore.messages.isEmpty) return;

    // Get last user message before removing
    String? lastUserMessage;
    if (globalStore.messages.length >= 2) {
      lastUserMessage =
          globalStore.messages[globalStore.messages.length - 2].content;
    }

    // Remove last two messages from store and database
    if (globalStore.messages.length >= 2) {
      // Delete from database
      await DATA.deleteMessage(id: globalStore.messages.last.id);
      await DATA.deleteMessage(
          id: globalStore.messages[globalStore.messages.length - 2].id);

      // Remove from store
      globalStore.messages.removeRange(
          globalStore.messages.length - 2, globalStore.messages.length);
      globalStore.setMessages(globalStore.messages); // Update state
    }

    // Set controller text to last user message and request focus
    if (lastUserMessage != null) {
      controller.text = lastUserMessage;
      focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final globalStore = Provider.of<GlobalStore>(context);
    final models = [
      "o3-mini",
      "o1-mini",
      'gpt-4o-mini',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DropdownButton<String>(
            isDense: true,
            underline: Container(),
            value: globalStore.model,
            items: models.map((String model) {
              return DropdownMenuItem<String>(
                value: model,
                child: Text(
                  model,
                  style: TextStyle(
                    fontSize: 12,
                    color: MyColors.txt.withOpacity(0.8),
                  ),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                globalStore.setModel(newValue);
              }
            },
          ),
          const SizedBox(width: 20),
          TextButton(
            onPressed: () => _redoLast(context),
            child: Text(
              'Redo Last',
              style: TextStyle(
                fontSize: 12,
                color: MyColors.txt.withOpacity(0.8),
              ),
            ),
          ),
          const SizedBox(width: 20),
          TextButton(
            onPressed: () => _clearChatHistory(context),
            child: Text(
              'Clear Chat',
              style: TextStyle(
                fontSize: 12,
                color: MyColors.txt.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
