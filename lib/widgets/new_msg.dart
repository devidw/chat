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

    globalStore.setStatus(Status.busy);

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

    globalStore.addMessage(userMsg);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (userMsg.key?.currentContext != null) {
        Scrollable.ensureVisible(
          userMsg.key!.currentContext!,
          alignment: 0,
          duration: Duration(milliseconds: 300),
        );
      }
    });

    String fullResponse = '';

    try {
      var stream = _aiService.generateText(
        hostUrl: globalStore.hostUrl,
        apiKey: globalStore.apiKey,
        model: globalStore.model,
        messages: globalStore.messages,
      );

      var botMsg = Msg(
        id: userMsgId + 1, // TODO: do better
        role: MsgRole.assistant,
        content: "",
      );

      var firstDone = false;

      await for (final chunk in stream) {
        fullResponse += chunk;

        if (!firstDone) {
          firstDone = true;
          globalStore.addMessage(botMsg);
        }

        globalStore.updateLastBotMsg(fullResponse);
      }
    } catch (e) {
      showErrorSnackBar(
          context, 'Failed to generate response: ${e.toString()}');
      setState(() {
        globalStore.messages.removeLast(); // Remove the empty bot message
      });
      return;
    } finally {
      globalStore.setStatus(Status.idle);
    }

    await DATA.createMessage(
      role: MsgRole.assistant.name,
      content: fullResponse,
      chatId: globalStore.currentChatId!,
      model: globalStore.model,
    );
  }

  bool _handleKeyPress(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.enter &&
        HardwareKeyboard.instance.isMetaPressed &&
        _textFieldHasFocus) {
      _onNewMsg(widget.controller.text);
      widget.controller.clear();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth < 700 ? screenWidth * 0.9 : 600.0;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            width: 1.5,
            color: _textFieldHasFocus
                ? MyColors.dark_txt.withValues(alpha: 0.5)
                : MyColors.dark_txt.withValues(alpha: 0.25),
          ),
        ),
      ),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          margin: EdgeInsets.symmetric(vertical: 10),
          padding: EdgeInsets.all(20),
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
                    hintText: "Message",
                    hintStyle: TextStyle(
                        // color: Colors.,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
