import 'package:app/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../global_store.dart';
import '../types.dart';

class Nav extends StatefulWidget {
  const Nav({super.key});

  @override
  State<Nav> createState() => _NavState();
}

class _NavState extends State<Nav> {
  @override
  void initState() {
    super.initState();
    ServicesBinding.instance.keyboard.addHandler(_handleKeyPress);
  }

  @override
  void dispose() {
    ServicesBinding.instance.keyboard.removeHandler(_handleKeyPress);
    super.dispose();
  }

  bool _handleKeyPress(KeyEvent event) {
    if (event is KeyDownEvent && HardwareKeyboard.instance.isMetaPressed) {
      final globalStore = Provider.of<GlobalStore>(context, listen: false);

      // Handle meta + 1-9
      if (event.logicalKey.keyLabel.length == 1) {
        final digit = int.tryParse(event.logicalKey.keyLabel);
        if (digit != null && digit >= 1 && digit <= 9) {
          final index = digit - 1;
          if (index < globalStore.tabs.length) {
            final chat = globalStore.tabs[index];
            globalStore.setCurrentChat(id: chat.id, name: chat.name);
            return true;
          }
        }
      }

      // Handle meta + w to close current tab
      if (event.logicalKey == LogicalKeyboardKey.keyW) {
        if (globalStore.currentChatId != null) {
          globalStore.removeTab(globalStore.currentChatId!);
          return true;
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final globalStore = Provider.of<GlobalStore>(context);

    return Container(
      height: 36,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: MyColors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: globalStore.tabs.length,
              itemBuilder: (context, index) {
                final chat = globalStore.tabs[index];
                final isSelected = chat.id == globalStore.currentChatId;

                return Container(
                  margin: const EdgeInsets.only(right: 1),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? MyColors.a.withOpacity(0.1)
                        : Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: isSelected ? MyColors.a : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  child: Row(
                    children: [
                      Text(
                        chat.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? MyColors.dark_txt : MyColors.grey,
                        ),
                      ),
                      if (isSelected && globalStore.status == Status.busy)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                MyColors.grey,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
