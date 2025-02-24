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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FocusNode _msgFocusNode = FocusNode();
  final TextEditingController _msgController = TextEditingController();
  bool _isPickerVisible = false;
  int? _prevChatId; // Track the previous chat ID

  @override
  void initState() {
    super.initState();
    DATA.mbInit();
    ServicesBinding.instance.keyboard.addHandler(_handleKeyPress);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the current chat id from your GlobalStore.
    final globalStore = Provider.of<GlobalStore>(context);
    final currentChatId = globalStore.currentChatId;

    // Only load messages if the chat id changed.
    if (currentChatId != null && currentChatId != _prevChatId) {
      _prevChatId = currentChatId;
      _loadMessages(context, currentChatId);
    }
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
              key: GlobalKey(), // Ideally, use a ValueKey if possible
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

  bool _handleKeyPress(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (HardwareKeyboard.instance.isMetaPressed) {
        if (event.logicalKey == LogicalKeyboardKey.keyT) {
          _showPicker(context);
          return true;
        } else if (event.logicalKey == LogicalKeyboardKey.semicolon) {
          _openSettings();
          return true;
        }
      }
    }
    return false;
  }

  void _showPicker(BuildContext context) {
    if (_isPickerVisible) {
      Navigator.of(context).pop();
      _isPickerVisible = false;
      return;
    }

    final globalStore = Provider.of<GlobalStore>(context, listen: false);
    _isPickerVisible = true;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => PickerDialog(
        onSelection: (chat) {
          globalStore.addTab(id: chat["id"], name: chat["name"]);
          globalStore.setCurrentChat(
            id: chat['id'],
            name: chat['name'],
          );
          _msgFocusNode.requestFocus();
        },
      ),
    ).then((_) {
      _isPickerVisible = false;
    });
  }

  void _openSettings() {
    Navigator.pushNamed(context, '/settings');
  }

  @override
  Widget build(BuildContext context) {
    final globalStore = Provider.of<GlobalStore>(context);

    // print("${DateTime.now()} home rerender");

    return Scaffold(
      body: globalStore.currentChatId != null
          ? Column(
              children: [
                const Nav(),
                const Expanded(child: ChatHistory()),
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
          : Center(
              child: Text(
                '⌘ T',
                textAlign: TextAlign.center,
              ),
            ),
    );
  }
}
