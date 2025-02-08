import 'package:app/styles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../global_store.dart';

class Nav extends StatelessWidget {
  const Nav({super.key});

  @override
  Widget build(BuildContext context) {
    final globalStore = Provider.of<GlobalStore>(context);

    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            '${globalStore.currentProjectName ?? ''} × ${globalStore.currentChatName ?? ''}',
            style: const TextStyle(
              fontSize: 12,
              color: MyColors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
