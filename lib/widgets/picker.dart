import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../db.dart';
import '../styles.dart';
import '../global_store.dart';

class PickerDialog extends StatefulWidget {
  final Function(Map<String, dynamic> project, Map<String, dynamic>? chat)
      onSelection;
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
  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _chats = [];
  int _selectedProjectIndex = 0;
  int _selectedChatIndex = 0;
  bool _isChatTab = false;
  bool _isRenaming = false;
  bool _showDeleteConfirm = false;
  final TextEditingController _renameController = TextEditingController();
  final FocusNode _renameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadProjects();
    final globalStore = Provider.of<GlobalStore>(context, listen: false);
    _isChatTab = globalStore.currentChatId != null;
    if (_isChatTab) {
      _loadChats(globalStore.currentProjectId!);
    }

    ServicesBinding.instance.keyboard.addHandler(_handleKeyPress);
  }

  @override
  void dispose() {
    _renameController.dispose();
    _renameFocusNode.dispose();
    ServicesBinding.instance.keyboard.removeHandler(_handleKeyPress);
    super.dispose();
  }

  Future<void> _loadProjects() async {
    final projects = await DATA.listProjects();
    final globalStore = Provider.of<GlobalStore>(context, listen: false);
    setState(() {
      _projects = projects;
      if (projects.isNotEmpty) {
        if (globalStore.currentProjectId != null) {
          final index = projects
              .indexWhere((p) => p['id'] == globalStore.currentProjectId);
          _selectedProjectIndex = index >= 0 ? index : 0;
        } else {
          _selectedProjectIndex = 0;
        }
      }
    });
  }

  Future<void> _loadChats(int projectId) async {
    final chats = await DATA.listChatsByProject(projectId: projectId);
    final globalStore = Provider.of<GlobalStore>(context, listen: false);
    setState(() {
      _chats = chats;
      if (chats.isNotEmpty) {
        if (globalStore.currentChatId != null) {
          final index =
              chats.indexWhere((c) => c['id'] == globalStore.currentChatId);
          _selectedChatIndex = index >= 0 ? index : 0;
        } else {
          _selectedChatIndex = 0;
        }
      } else {
        _selectedChatIndex = -1;
      }
    });
  }

  Future<void> _createNewProject() async {
    final projectId = await DATA.createProject();
    await _loadProjects();
    setState(() {
      _selectedProjectIndex = _projects.length - 1;
      _isRenaming = true;
      _renameController.text = 'Untitled Project';
    });
    _renameFocusNode.requestFocus();
  }

  Future<void> _createNewChat() async {
    final projectId = _projects[_selectedProjectIndex]['id'];
    final chatId = await DATA.createChat(projectId: projectId);
    await _loadChats(projectId);
    setState(() {
      _selectedChatIndex = _chats.length - 1;
      _isRenaming = true;
      _renameController.text = 'Untitled Chat';
    });
    _renameFocusNode.requestFocus();
  }

  Future<void> _handleRename() async {
    if (_isChatTab && _selectedChatIndex >= 0) {
      final chat = _chats[_selectedChatIndex];
      _renameController.text = chat['name'];
      setState(() {
        _isRenaming = true;
      });
      _renameFocusNode.requestFocus();
    } else if (!_isChatTab && _selectedProjectIndex >= 0) {
      final project = _projects[_selectedProjectIndex];
      _renameController.text = project['name'];
      setState(() {
        _isRenaming = true;
      });
      _renameFocusNode.requestFocus();
    }
  }

  Future<void> _saveRename() async {
    if (_isChatTab && _selectedChatIndex >= 0) {
      final chat = _chats[_selectedChatIndex];
      await DATA.updateChat(id: chat['id'], name: _renameController.text);
      final projectId = _projects[_selectedProjectIndex]['id'];
      final chats = await DATA.listChatsByProject(projectId: projectId);
      setState(() {
        _chats = chats;
        _isRenaming = false;
      });
    } else if (!_isChatTab && _selectedProjectIndex >= 0) {
      final project = _projects[_selectedProjectIndex];
      await DATA.updateProject(id: project['id'], name: _renameController.text);
      final projects = await DATA.listProjects();
      setState(() {
        _projects = projects;
        _isRenaming = false;
      });
    }
  }

  Future<void> _handleDelete() async {
    if (_isChatTab && _selectedChatIndex >= 0) {
      final chat = _chats[_selectedChatIndex];
      await DATA.deleteChat(id: chat['id']);
      await _loadChats(_projects[_selectedProjectIndex]['id']);
    } else if (!_isChatTab && _selectedProjectIndex >= 0) {
      final project = _projects[_selectedProjectIndex];
      await DATA.deleteProject(id: project['id']);
      await _loadProjects();
      setState(() {
        _isChatTab = false;
      });
    }
    setState(() {
      _showDeleteConfirm = false;
    });
  }

  void _handleProjectSelection() {
    setState(() {
      _isChatTab = true;
    });
    _loadChats(_projects[_selectedProjectIndex]['id']);
  }

  void _handleChatSelection() {
    widget.onSelection(
      _projects[_selectedProjectIndex],
      _chats[_selectedChatIndex],
    );
    Navigator.of(context).pop();
  }

  bool _handleKeyPress(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    if (_showDeleteConfirm) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        _handleDelete();
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _showDeleteConfirm = false;
        });
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
      if (_isChatTab) {
        _createNewChat();
      } else {
        _createNewProject();
      }
      return true;
    }

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        setState(() {
          if (_isChatTab && _chats.isNotEmpty) {
            _selectedChatIndex = (_selectedChatIndex + 1) % _chats.length;
          } else if (!_isChatTab && _projects.isNotEmpty) {
            _selectedProjectIndex =
                (_selectedProjectIndex + 1) % _projects.length;
          }
        });
        return true;

      case LogicalKeyboardKey.arrowUp:
        setState(() {
          if (_isChatTab && _chats.isNotEmpty) {
            _selectedChatIndex =
                (_selectedChatIndex - 1 + _chats.length) % _chats.length;
          } else if (!_isChatTab && _projects.isNotEmpty) {
            _selectedProjectIndex =
                (_selectedProjectIndex - 1 + _projects.length) %
                    _projects.length;
          }
        });
        return true;

      case LogicalKeyboardKey.arrowRight:
        if (_isChatTab && _selectedChatIndex >= 0) {
          _handleChatSelection();
        } else if (!_isChatTab && _selectedProjectIndex >= 0) {
          _handleProjectSelection();
        }
        return true;

      case LogicalKeyboardKey.arrowLeft:
        if (_isChatTab) {
          setState(() {
            _isChatTab = false;
          });
        }
        return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: MyColors.bg,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            width: 1.5,
            color: MyColors.txt.withValues(alpha: 0.25),
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
                      Text('View: ${_isChatTab ? "Chats" : "Projects"}'),
                      if (!_isChatTab &&
                          _selectedProjectIndex >= 0 &&
                          _projects.isNotEmpty)
                        Text(
                            'Selected Project: ${_projects[_selectedProjectIndex]['name']} (id: ${_projects[_selectedProjectIndex]['id']})'),
                      if (_isChatTab &&
                          _selectedProjectIndex >= 0 &&
                          _projects.isNotEmpty)
                        Text(
                            'Selected Project: ${_projects[_selectedProjectIndex]['name']} (id: ${_projects[_selectedProjectIndex]['id']})'),
                      if (_isChatTab &&
                          _selectedChatIndex >= 0 &&
                          _chats.isNotEmpty)
                        Text(
                            'Selected Chat: ${_chats[_selectedChatIndex]['name']} (id: ${_chats[_selectedChatIndex]['id']})'),
                    ],
                  ),
                ),
              Text.rich(
                TextSpan(
                  children: [
                    if (_isChatTab && _projects.isNotEmpty)
                      TextSpan(
                        text: _projects[_selectedProjectIndex]['name'],
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          color: MyColors.grey,
                        ),
                      ),
                    if (_isChatTab && _projects.isNotEmpty)
                      TextSpan(
                        text: "'s Chats",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: MyColors.grey,
                        ),
                      )
                    else
                      TextSpan(
                        text: 'Projects',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: MyColors.grey,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isChatTab && _chats.isEmpty
                    ? Center(child: Text('No chats available'))
                    : !_isChatTab && _projects.isEmpty
                        ? Center(child: Text('No projects available'))
                        : Column(
                            children: [
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _isChatTab
                                      ? _chats.length
                                      : _projects.length,
                                  itemBuilder: (context, index) {
                                    final item = _isChatTab
                                        ? _chats[index]
                                        : _projects[index];
                                    final isSelected = _isChatTab
                                        ? index == _selectedChatIndex
                                        : index == _selectedProjectIndex;

                                    if (_isRenaming && isSelected) {
                                      return ListTile(
                                        title: TextField(
                                          controller: _renameController,
                                          focusNode: _renameFocusNode,
                                          style: TextStyle(fontSize: 13),
                                          decoration: InputDecoration(
                                            isDense: true,
                                            border: InputBorder.none,
                                          ),
                                        ),
                                        tileColor:
                                            MyColors.a.withValues(alpha: 0.5),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        dense: true,
                                      );
                                    }

                                    return ListTile(
                                      title: Text(
                                        item['name'],
                                        style: TextStyle(
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: MyColors.txt,
                                        ),
                                      ),
                                      tileColor: isSelected
                                          ? _showDeleteConfirm
                                              ? Colors.red
                                                  .withValues(alpha: 0.3)
                                              : MyColors.a
                                                  .withValues(alpha: 0.3)
                                          : null,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
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
      ),
    );
  }
}
