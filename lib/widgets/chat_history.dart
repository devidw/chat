import 'package:app/widgets/msg.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../global_store.dart';

class ChatHistory extends StatefulWidget {
  const ChatHistory({super.key});

  @override
  State<ChatHistory> createState() => _ChatHistoryState();
}

class _ChatHistoryState extends State<ChatHistory> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final globalStore = Provider.of<GlobalStore>(context);

    // print("${DateTime.now()} chat history rerender");

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                ...globalStore.messages.map((msg) => MsgWidget(msg: msg)),
                const SizedBox(height: 1200),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
