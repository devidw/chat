import 'package:flutter/material.dart';

enum Status { idle, busy }

enum MsgRole { user, assistant }

class Msg {
  int id;
  GlobalKey? key;
  MsgRole role;
  String content;

  Msg({
    this.key,
    required this.id,
    required this.role,
    required this.content,
  });
}
