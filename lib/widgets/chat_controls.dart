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
    final lastMsg = globalStore.messages.last;

    if (lastMsg.role.name == 'assistant' && globalStore.messages.length >= 2) {
      // If last message is from bot, get the user message before it
      lastUserMessage =
          globalStore.messages[globalStore.messages.length - 2].content;

      // Delete both messages from database
      await DATA.deleteMessage(id: lastMsg.id);
      await DATA.deleteMessage(
          id: globalStore.messages[globalStore.messages.length - 2].id);

      // Remove both from store
      globalStore.messages.removeRange(
          globalStore.messages.length - 2, globalStore.messages.length);
    } else if (lastMsg.role.name == 'user') {
      // If last message is from user, just get and remove that
      lastUserMessage = lastMsg.content;

      // Delete from database
      await DATA.deleteMessage(id: lastMsg.id);

      // Remove from store
      globalStore.messages.removeLast();
    }

    globalStore.setMessages(globalStore.messages); // Update state

    // Set controller text to last user message and request focus
    if (lastUserMessage != null) {
      controller.text = lastUserMessage;
      focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final globalStore = Provider.of<GlobalStore>(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Model selector
          DropdownButton<String>(
            isDense: true,
            underline: Container(),
            value: globalStore.model,
            items: globalStore.availableModels.map((model) {
              return DropdownMenuItem<String>(
                value: model['id'],
                child: Text(
                  model['name']!,
                  style: TextStyle(
                    fontSize: 12,
                    color: MyColors.dark_txt.withOpacity(0.8),
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
          Row(
            children: [
              TextButton(
                onPressed: () => _redoLast(context),
                child: Text(
                  'Redo Last',
                  style: TextStyle(
                    fontSize: 12,
                    color: MyColors.dark_txt.withOpacity(0.8),
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
                    color: MyColors.dark_txt.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
