import "package:app/md_stylesheet.dart";
import "package:app/styles.dart";
import "package:app/widgets/highlight.dart";
import "package:flutter/material.dart";
import "package:app/types.dart";
import "package:flutter_markdown/flutter_markdown.dart";
import "package:flutter/services.dart";
import "package:app/db.dart";
import "package:app/global_store.dart";
import "package:provider/provider.dart";

class MsgWidget extends StatelessWidget {
  final Msg msg;

  const MsgWidget({
    super.key,
    required this.msg,
  });

  Future<void> _handleDelete(BuildContext context) async {
    final store = Provider.of<GlobalStore>(context, listen: false);
    await DATA.deleteMessage(id: msg.id);
    store.setMessages(store.messages.where((m) => m.id != msg.id).toList());
  }

  void _handleCopy() {
    Clipboard.setData(ClipboardData(text: msg.content));
  }

  Widget _buildActionButtons(BuildContext context) {
    // if (msg.role == MsgRole.assistant) {
    //   print("${DateTime.now()} ${msg.id} ${msg.content}");
    // }

    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.copy_outlined, size: 16),
          onPressed: _handleCopy,
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(),
          splashRadius: 16,
          color: MyColors.a.withOpacity(0.5),
        ),
        SizedBox(width: 8),
        IconButton(
          icon: Icon(Icons.delete_outline, size: 16),
          onPressed: () => _handleDelete(context),
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(),
          splashRadius: 16,
          color: MyColors.a.withOpacity(0.5),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth < 700 ? screenWidth * 0.9 : 600.0;

    if (msg.role == MsgRole.assistant) {
      return Center(
        child: Container(
          width: maxWidth,
          margin: EdgeInsets.only(top: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MarkdownBody(
                data: msg.content.isEmpty ? "…" : msg.content,
                selectable: true,
                styleSheet: stylehseet,
                builders: {
                  "code": MyHighLightBuilder(),
                },
              ),
              SizedBox(height: 8),
              Container(
                margin: EdgeInsets.only(
                  left: 20,
                  top: 10,
                ),
                child: _buildActionButtons(context),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: SizedBox(
        width: maxWidth,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IntrinsicWidth(
              child: Container(
                constraints: BoxConstraints(maxWidth: maxWidth * 0.8),
                margin: EdgeInsets.only(top: 40),
                padding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: MyColors.a.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SelectableText(
                      msg.content,
                      style: TextStyle(
                        height: 1.75,
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        fontVariations: [
                          FontVariation("wght", 300),
                        ],
                      ),
                    ),
                    SizedBox(height: 4),
                    _buildActionButtons(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
