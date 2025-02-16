import "package:app/md_stylesheet.dart";
import "package:app/styles.dart";
import "package:app/widgets/highlight.dart";
import "package:flutter/material.dart";
import "package:app/types.dart";
import "package:flutter_markdown/flutter_markdown.dart";
import "package:flutter/services.dart";
import "package:google_fonts/google_fonts.dart";

class MsgWidget extends StatefulWidget {
  final Msg msg;

  const MsgWidget({
    super.key,
    required this.msg,
  });

  @override
  State<MsgWidget> createState() => _MsgWidgetState();
}

class _MsgWidgetState extends State<MsgWidget> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth < 700 ? screenWidth * 0.9 : 600.0;

    if (widget.msg.role == MsgRole.assistant) {
      return Center(
        child: Container(
          width: maxWidth,
          margin: EdgeInsets.only(top: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MarkdownBody(
                data: widget.msg.content.isEmpty ? "…" : widget.msg.content,
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
                child: IconButton(
                  icon: Icon(Icons.copy_outlined, size: 16),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.msg.content));
                  },
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  splashRadius: 16,
                  color: MyColors.a.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Container(
        width: maxWidth,
        alignment: Alignment.centerRight,
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
          child: SelectableText(
            widget.msg.content,
            style: TextStyle(
              height: 1.75,
              fontSize: 16,
              fontStyle: FontStyle.italic,
              fontVariations: [
                FontVariation("wght", 300),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
