import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../db.dart';
import '../styles.dart';
import '../global_store.dart';

class PickerDialog extends StatefulWidget {
  final Function(Map<String, dynamic> chat) onSelection;
  final bool showDebugInfo;

  const PickerDialog({
    super.key,
    required this.onSelection,
    this.showDebugInfo = false,
  });

  @override
  _PickerDialogState createState() => _PickerDialogState();
}

class _PickerDialogState extends State<PickerDialog> {
  List<Map<String, dynamic>> _parentChats = [];
  List<Map<String, dynamic>> _childChats = [];
  int _selectedParentIndex = 0;
  int _selectedChildIndex = 0;
  bool _isChildView = false;
  bool _isRenaming = false;
  bool _showDeleteConfirm = false;
  final TextEditingController _renameController = TextEditingController();
  final FocusNode _renameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeChats();
    ServicesBinding.instance.keyboard.addHandler(_handleKeyPress);
  }

  Future<void> _initializeChats() async {
    final globalStore = Provider.of<GlobalStore>(context, listen: false);
    final currentChatId = globalStore.currentChatId;

    // First load all parent chats
    final parentChats = await DATA.listChats();
    setState(() {
      _parentChats = parentChats;
    });

    if (currentChatId != null) {
      // Find if current chat is a parent
      final parentIndex =
          parentChats.indexWhere((p) => p['id'] == currentChatId);

      if (parentIndex >= 0) {
        // Current chat is a parent
        setState(() {
          _selectedParentIndex = parentIndex;
          _isChildView = false;
        });
      } else {
        // Current chat might be a child, need to find its parent
        for (var i = 0; i < parentChats.length; i++) {
          final childChats =
              await DATA.listChats(parentId: parentChats[i]['id']);
          final childIndex =
              childChats.indexWhere((c) => c['id'] == currentChatId);

          if (childIndex >= 0) {
            setState(() {
              _selectedParentIndex = i;
              _childChats = childChats;
              _selectedChildIndex = childIndex;
              _isChildView = true;
            });
            break;
          }
        }
      }
    } else if (parentChats.isNotEmpty) {
      // No current chat, select first parent
      setState(() {
        _selectedParentIndex = 0;
        _isChildView = false;
      });
    }
  }

  @override
  void dispose() {
    _renameController.dispose();
    _renameFocusNode.dispose();
    ServicesBinding.instance.keyboard.removeHandler(_handleKeyPress);
    super.dispose();
  }

  Future<void> _loadParentChats() async {
    final chats = await DATA.listChats();
    setState(() {
      _parentChats = chats;
      if (_selectedParentIndex >= chats.length) {
        _selectedParentIndex = chats.isEmpty ? -1 : 0;
      }
    });
  }

  Future<void> _loadChildChats(int parentId) async {
    final chats = await DATA.listChats(parentId: parentId);
    setState(() {
      _childChats = chats;
      _selectedChildIndex = chats.isEmpty ? -1 : 0;
    });
  }

  Future<void> _createNewParentChat() async {
    final chatId = await DATA.createChat();
    await _loadParentChats();
    final newChatIndex =
        _parentChats.indexWhere((chat) => chat['id'] == chatId);
    setState(() {
      _selectedParentIndex = newChatIndex;
      _isRenaming = true;
      _renameController.text = 'Untitled Chat';
      _isChildView = false;
      _selectedChildIndex = -1;
    });
    _renameFocusNode.requestFocus();
  }

  Future<void> _createNewChildChat() async {
    if (_parentChats.isEmpty || _selectedParentIndex < 0) return;

    final parentId = _parentChats[_selectedParentIndex]['id'];
    final chatId = await DATA.createChat(parentId: parentId);
    await _loadChildChats(parentId);
    final newChatIndex = _childChats.indexWhere((chat) => chat['id'] == chatId);
    setState(() {
      _selectedChildIndex = newChatIndex;
      _isRenaming = true;
      _renameController.text = 'Untitled Chat';
      _isChildView = true;
    });
    _renameFocusNode.requestFocus();
  }

  Future<void> _handleRename() async {
    if (_isChildView && _selectedChildIndex >= 0 && _childChats.isNotEmpty) {
      final chat = _childChats[_selectedChildIndex];
      _renameController.text = chat['name'];
      setState(() {
        _isRenaming = true;
      });
      _renameFocusNode.requestFocus();
    } else if (!_isChildView &&
        _selectedParentIndex >= 0 &&
        _parentChats.isNotEmpty) {
      final chat = _parentChats[_selectedParentIndex];
      _renameController.text = chat['name'];
      setState(() {
        _isRenaming = true;
      });
      _renameFocusNode.requestFocus();
    }
  }

  Future<void> _saveRename() async {
    if (_renameController.text.trim().isEmpty) {
      setState(() {
        _isRenaming = false;
      });
      return;
    }

    if (_isChildView && _selectedChildIndex >= 0 && _childChats.isNotEmpty) {
      final chat = _childChats[_selectedChildIndex];
      final currentChildIndex = _selectedChildIndex;
      await DATA.updateChat(id: chat['id'], name: _renameController.text);
      final parentId = _parentChats[_selectedParentIndex]['id'];
      await _loadChildChats(parentId);
      setState(() {
        _selectedChildIndex = currentChildIndex;
      });
    } else if (!_isChildView &&
        _selectedParentIndex >= 0 &&
        _parentChats.isNotEmpty) {
      final chat = _parentChats[_selectedParentIndex];
      await DATA.updateChat(id: chat['id'], name: _renameController.text);
      final currentIndex = _selectedParentIndex;
      await _loadParentChats();
      setState(() {
        _selectedParentIndex = currentIndex;
      });
    }

    setState(() {
      _isRenaming = false;
    });
  }

  Future<void> _handleDelete() async {
    if (_isChildView && _selectedChildIndex >= 0 && _childChats.isNotEmpty) {
      final chat = _childChats[_selectedChildIndex];
      await DATA.deleteChat(id: chat['id']);

      // Remove from global store first
      Provider.of<GlobalStore>(context, listen: false).removeTab(chat["id"]);

      // Reload child chats and update selection
      await _loadChildChats(_parentChats[_selectedParentIndex]['id']);
      setState(() {
        _selectedChildIndex = _childChats.isEmpty
            ? -1
            : _selectedChildIndex >= _childChats.length
                ? _childChats.length - 1
                : _selectedChildIndex;
        _showDeleteConfirm = false;
      });
    } else if (!_isChildView &&
        _selectedParentIndex >= 0 &&
        _parentChats.isNotEmpty) {
      final chat = _parentChats[_selectedParentIndex];
      await DATA.deleteChat(id: chat['id']);

      // Remove from global store first
      Provider.of<GlobalStore>(context, listen: false).removeTab(chat["id"]);

      // Reload parent chats and update selection
      await _loadParentChats();
      setState(() {
        _isChildView = false;
        _selectedParentIndex = _parentChats.isEmpty
            ? -1
            : _selectedParentIndex >= _parentChats.length
                ? _parentChats.length - 1
                : _selectedParentIndex;
        _selectedChildIndex = -1;
        _showDeleteConfirm = false;
      });
    }
  }

  void _handleParentSelection() {
    setState(() {
      _isChildView = true;
      _childChats = []; // Clear chats while loading
    });
    _loadChildChats(_parentChats[_selectedParentIndex]['id']);
  }

  void _handleChatSelection() {
    if (_isChildView && _selectedChildIndex >= 0) {
      widget.onSelection(_childChats[_selectedChildIndex]);
    } else if (!_isChildView && _selectedParentIndex >= 0) {
      widget.onSelection(_parentChats[_selectedParentIndex]);
    }
    Navigator.of(context).pop();
  }

  bool _handleKeyPress(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    // Handle escape key first
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (_showDeleteConfirm) {
        setState(() {
          _showDeleteConfirm = false;
        });
        return true;
      }
      if (_isRenaming) {
        setState(() {
          _isRenaming = false;
        });
        return true;
      }
      Navigator.of(context).pop();
      return true;
    }

    if (_showDeleteConfirm) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        _handleDelete();
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.escape) {
        setState(() {
          _showDeleteConfirm = false;
        });
        return true;
      }
    }

    if (_isRenaming) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        _saveRename();
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        setState(() {
          _isRenaming = false;
        });
      }
      return false;
    }

    if (HardwareKeyboard.instance.isMetaPressed &&
        event.logicalKey == LogicalKeyboardKey.keyR) {
      _handleRename();
      return true;
    }

    if (HardwareKeyboard.instance.isMetaPressed &&
        event.logicalKey == LogicalKeyboardKey.keyD) {
      setState(() {
        _showDeleteConfirm = true;
      });
      return true;
    }

    if (HardwareKeyboard.instance.isMetaPressed &&
        event.logicalKey == LogicalKeyboardKey.keyA) {
      if (_isChildView) {
        _createNewChildChat();
      } else {
        _createNewParentChat();
      }
      return true;
    }

    if (_showDeleteConfirm) {
      return true; // Block navigation when delete confirmation is shown
    }

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        setState(() {
          if (_isChildView && _childChats.isNotEmpty) {
            _selectedChildIndex =
                (_selectedChildIndex + 1) % _childChats.length;
          } else if (!_isChildView && _parentChats.isNotEmpty) {
            _selectedParentIndex =
                (_selectedParentIndex + 1) % _parentChats.length;
            _selectedChildIndex = -1;
            _childChats = []; // Clear chats when changing parent
            if (_isChildView) {
              _loadChildChats(_parentChats[_selectedParentIndex]
                  ['id']); // Reload chats if in child view
            }
          }
        });
        return true;

      case LogicalKeyboardKey.arrowUp:
        setState(() {
          if (_isChildView && _childChats.isNotEmpty) {
            _selectedChildIndex =
                (_selectedChildIndex - 1 + _childChats.length) %
                    _childChats.length;
          } else if (!_isChildView && _parentChats.isNotEmpty) {
            _selectedParentIndex =
                (_selectedParentIndex - 1 + _parentChats.length) %
                    _parentChats.length;
            _selectedChildIndex = -1;
            _childChats = []; // Clear chats when changing parent
            if (_isChildView) {
              _loadChildChats(_parentChats[_selectedParentIndex]
                  ['id']); // Reload chats if in child view
            }
          }
        });
        return true;

      case LogicalKeyboardKey.arrowRight:
        if (!_isChildView && _selectedParentIndex >= 0) {
          _handleParentSelection();
        }
        return true;

      case LogicalKeyboardKey.arrowLeft:
        if (_isChildView) {
          setState(() {
            _isChildView = false;
            _selectedChildIndex = -1;
          });
        }
        return true;

      case LogicalKeyboardKey.enter:
        _handleChatSelection();
        return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).dialogBackgroundColor,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            width: 1.5,
            color: MyColors.dark_txt.withValues(alpha: 0.25),
          ),
        ),
        constraints: BoxConstraints(
          minWidth: 300,
          maxWidth: 600,
          minHeight: 200,
          maxHeight: 800,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.showDebugInfo)
                Container(
                  padding: EdgeInsets.all(8),
                  color: Colors.grey[800],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Debug Info:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                          'View: ${_isChildView ? "Child Chats" : "Parent Chats"}'),
                      if (!_isChildView &&
                          _selectedParentIndex >= 0 &&
                          _parentChats.isNotEmpty)
                        Text(
                            'Selected Parent Chat: ${_parentChats[_selectedParentIndex]['name']} (id: ${_parentChats[_selectedParentIndex]['id']})'),
                      if (_isChildView &&
                          _selectedParentIndex >= 0 &&
                          _parentChats.isNotEmpty)
                        Text(
                            'Selected Parent Chat: ${_parentChats[_selectedParentIndex]['name']} (id: ${_parentChats[_selectedParentIndex]['id']})'),
                      if (_isChildView &&
                          _selectedChildIndex >= 0 &&
                          _childChats.isNotEmpty)
                        Text(
                            'Selected Child Chat: ${_childChats[_selectedChildIndex]['name']} (id: ${_childChats[_selectedChildIndex]['id']})'),
                    ],
                  ),
                ),
              Expanded(
                child: Row(
                  children: [
                    // Left column for parent chats
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: _parentChats.isEmpty
                                ? Center(child: Text('No chats available'))
                                : ListView.builder(
                                    itemCount: _parentChats.length,
                                    itemBuilder: (context, index) {
                                      final chat = _parentChats[index];
                                      final isSelected =
                                          index == _selectedParentIndex;
                                      return ListTile(
                                        title: Row(
                                          children: [
                                            Expanded(
                                              child: isSelected &&
                                                      _isRenaming &&
                                                      !_isChildView
                                                  ? TextField(
                                                      controller:
                                                          _renameController,
                                                      focusNode:
                                                          _renameFocusNode,
                                                      decoration:
                                                          InputDecoration(
                                                        border:
                                                            InputBorder.none,
                                                        contentPadding:
                                                            EdgeInsets.zero,
                                                      ),
                                                      style: TextStyle(
                                                        color:
                                                            MyColors.dark_txt,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                      onSubmitted: (_) =>
                                                          _saveRename(),
                                                      onEditingComplete:
                                                          _saveRename,
                                                    )
                                                  : Text(
                                                      chat['name'],
                                                      style: TextStyle(
                                                        fontWeight: isSelected
                                                            ? FontWeight.bold
                                                            : FontWeight.normal,
                                                        color: isSelected &&
                                                                _showDeleteConfirm &&
                                                                !_isChildView
                                                            ? Colors.red
                                                            : MyColors.dark_txt,
                                                      ),
                                                    ),
                                            ),
                                          ],
                                        ),
                                        tileColor: isSelected
                                            ? (_isChildView
                                                ? MyColors.a
                                                    .withValues(alpha: 0.1)
                                                : _showDeleteConfirm
                                                    ? Colors.red
                                                        .withOpacity(0.2)
                                                    : MyColors.a
                                                        .withValues(alpha: 0.3))
                                            : null,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        dense: true,
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                    // Right column for child chats
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: _childChats.isEmpty
                                ? Center(
                                    child: Text(
                                      _isChildView ? '⌘ A' : '⌘ →',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color
                                            ?.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _childChats.length,
                                    itemBuilder: (context, index) {
                                      final chat = _childChats[index];
                                      final isSelected =
                                          index == _selectedChildIndex;
                                      return ListTile(
                                        title: Row(
                                          children: [
                                            Expanded(
                                              child: isSelected &&
                                                      _isRenaming &&
                                                      _isChildView
                                                  ? TextField(
                                                      controller:
                                                          _renameController,
                                                      focusNode:
                                                          _renameFocusNode,
                                                      decoration:
                                                          InputDecoration(
                                                        border:
                                                            InputBorder.none,
                                                        contentPadding:
                                                            EdgeInsets.zero,
                                                      ),
                                                      style: TextStyle(
                                                        color:
                                                            MyColors.dark_txt,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                      onSubmitted: (_) =>
                                                          _saveRename(),
                                                      onEditingComplete:
                                                          _saveRename,
                                                    )
                                                  : Text(
                                                      chat['name'],
                                                      style: TextStyle(
                                                        fontWeight: isSelected
                                                            ? FontWeight.bold
                                                            : FontWeight.normal,
                                                        color: isSelected &&
                                                                _showDeleteConfirm &&
                                                                _isChildView
                                                            ? Colors.red
                                                            : MyColors.dark_txt,
                                                      ),
                                                    ),
                                            ),
                                          ],
                                        ),
                                        tileColor: isSelected
                                            ? _showDeleteConfirm
                                                ? Colors.red.withOpacity(0.2)
                                                : MyColors.a
                                                    .withValues(alpha: 0.3)
                                            : null,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        dense: true,
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
