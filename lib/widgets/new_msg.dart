import "package:app/ai.dart";
import "package:app/db.dart";
import "package:app/styles.dart";
import "package:app/types.dart";
import "package:app/widgets/error_snackbar.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:provider/provider.dart";
import "../global_store.dart";

class NewMsgWidget extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  const NewMsgWidget({
    super.key,
    required this.controller,
    required this.focusNode,
  });

  @override
  State<NewMsgWidget> createState() => _NewMsgWidgetState();
}

class _NewMsgWidgetState extends State<NewMsgWidget> {
  final AIService _aiService = AIService();
  bool _textFieldHasFocus = false;
  Status status = Status.idle;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() {
      setState(() {
        _textFieldHasFocus = widget.focusNode.hasFocus;
      });
    });
    ServicesBinding.instance.keyboard.addHandler(_handleKeyPress);
  }

  @override
  void dispose() {
    widget.focusNode.dispose();
    ServicesBinding.instance.keyboard.removeHandler(_handleKeyPress);
    super.dispose();
  }

  Future<void> _onNewMsg(String content) async {
    final globalStore = Provider.of<GlobalStore>(context, listen: false);
    if (globalStore.currentChatId == null) return;

    var userMsgId = await DATA.createMessage(
      role: MsgRole.user.name,
      content: content,
      chatId: globalStore.currentChatId!,
    );

    var userMsg = Msg(
      id: userMsgId,
      key: GlobalKey(),
      role: MsgRole.user,
      content: content,
    );

    setState(() {
      globalStore.addMessage(userMsg);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (userMsg.key?.currentContext != null) {
        Scrollable.ensureVisible(
          userMsg.key!.currentContext!,
          alignment: 0,
          duration: Duration(milliseconds: 300),
        );
      }
    });

    var botMsg = Msg(
      id: userMsgId + 1, // TODO: do better
      role: MsgRole.assistant,
      content: "",
    );

    setState(() {
      status = Status.busy;
      globalStore.addMessage(botMsg);
    });

    String fullResponse = '';

    try {
      var stream = _aiService.generateText(
        model: globalStore.model,
        messages: globalStore.messages,
      );

      await for (final chunk in stream) {
        fullResponse += chunk;
        globalStore.updateLastBotMsg(fullResponse);
      }
    } catch (e) {
      showErrorSnackBar(
          context, 'Failed to generate response: ${e.toString()}');
      setState(() {
        status = Status.idle;
        globalStore.messages.removeLast(); // Remove the empty bot message
      });
      return;
    }

    await DATA.createMessage(
      role: botMsg.role.name,
      content: fullResponse,
      chatId: globalStore.currentChatId!,
      model: globalStore.model,
    );

    setState(() {
      status = Status.idle;
    });
  }

  bool _handleKeyPress(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (HardwareKeyboard.instance.isMetaPressed &&
          event.logicalKey == LogicalKeyboardKey.enter) {
        if (widget.controller.text.trim().isNotEmpty) {
          _onNewMsg(widget.controller.text);
          widget.controller.clear();
          return true;
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            width: 1.5,
            color: _textFieldHasFocus
                ? MyColors.txt.withValues(alpha: 0.5)
                : MyColors.txt.withValues(alpha: 0.25),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              minLines: 3,
              maxLines: null,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: Colors.white54,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
