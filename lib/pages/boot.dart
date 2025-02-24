import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BootPage extends StatefulWidget {
  const BootPage({super.key});

  @override
  State<BootPage> createState() => _BootPageState();
}

class _BootPageState extends State<BootPage> {
  @override
  void initState() {
    super.initState();
    _checkSettings();
  }

  Future<void> _checkSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final dbPath = prefs.getString('db_path');

    if (mounted) {
      if (dbPath == null || dbPath.isEmpty) {
        // If db_path is not set, navigate to settings
        Navigator.of(context).pushReplacementNamed('/settings');
      } else {
        // If db_path is set, navigate to home
        Navigator.of(context).pushReplacementNamed('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
