import "package:app/styles.dart";
import "package:app/widgets/highlight.dart";
import "package:flutter/material.dart";
import "package:app/types.dart";
import "package:flutter_markdown/flutter_markdown.dart";

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
    return Row(
      key: widget.msg.key,
      mainAxisAlignment: widget.msg.role == MsgRole.user
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(maxWidth: 600),
          margin: EdgeInsets.all(10),
          padding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: widget.msg.role == MsgRole.user ? Colors.white10 : null,
          ),
          child: MarkdownBody(
            data: widget.msg.role == MsgRole.assistant &&
                    widget.msg.content.isEmpty
                ? "…"
                : widget.msg.content,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(
                height: 1.75,
                fontSize: 16,
              ),
              a: TextStyle(
                color: MyColors.a,
              ),
            ),
            builders: {
              "code": MyHighLightBuilder(),
            },
          ),
          // SelectableText(
          //   widget.msg.content,
          //   style: TextStyle(height: 2),
          // ),
        )
      ],
    );
  }
}
