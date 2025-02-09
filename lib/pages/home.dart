import 'package:app/widgets/chat_controls.dart';
import 'package:app/widgets/new_msg.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../global_store.dart';
import '../widgets/chat_history.dart';
import '../widgets/picker.dart';
import '../types.dart';
import '../db.dart';
import '../widgets/nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FocusNode _msgFocusNode = FocusNode();
  final TextEditingController _msgController = TextEditingController();

  @override
  void initState() {
    super.initState();
    ServicesBinding.instance.keyboard.addHandler(_handleKeyPress);
  }

  @override
  void dispose() {
    ServicesBinding.instance.keyboard.removeHandler(_handleKeyPress);
    _msgFocusNode.dispose();
    _msgController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages(BuildContext context, int chatId) async {
    final globalStore = Provider.of<GlobalStore>(context, listen: false);
    final messages = await DATA.listMessagesByChat(chatId: chatId);
    final mappedMessages = messages
        .map((m) => Msg(
              id: m["id"],
              role: m['role'] == 'user' ? MsgRole.user : MsgRole.assistant,
              content: m['content'],
              key: GlobalKey(),
            ))
        .toList();
    globalStore.setMessages(mappedMessages);

    if (mappedMessages.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Find last user message
        Msg? lastUserMsg;
        for (var i = mappedMessages.length - 1; i >= 0; i--) {
          if (mappedMessages[i].role == MsgRole.user) {
            lastUserMsg = mappedMessages[i];
            break;
          }
        }

        if (lastUserMsg?.key?.currentContext != null) {
          Scrollable.ensureVisible(
            lastUserMsg!.key!.currentContext!,
            alignment: 0,
            duration: const Duration(milliseconds: 300),
          );
        }
      });
    }
  }

  void _showPicker(BuildContext context) {
    final globalStore = Provider.of<GlobalStore>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => PickerDialog(
        onSelection: (project, chat) {
          globalStore.setCurrentProject(
            id: project['id'],
            name: project['name'],
          );

          if (chat != null) {
            globalStore.setCurrentChat(
              id: chat['id'],
              name: chat['name'],
            );

            _loadMessages(context, chat['id']);
            _msgFocusNode.requestFocus();
          }
        },
      ),
    );
  }

  bool _handleKeyPress(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyT &&
          HardwareKeyboard.instance.isMetaPressed) {
        _showPicker(context);
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final globalStore = Provider.of<GlobalStore>(context);

    return Scaffold(
      body: globalStore.currentChatId != null
          ? Column(
              children: [
                const Nav(),
                const Expanded(
                  child: ChatHistory(),
                ),
                ChatControls(
                  focusNode: _msgFocusNode,
                  controller: _msgController,
                ),
                NewMsgWidget(
                  focusNode: _msgFocusNode,
                  controller: _msgController,
                ),
              ],
            )
          : const Center(
              child: Text(
                '⌘ + T',
                textAlign: TextAlign.center,
              ),
            ),
    );
  }
}
