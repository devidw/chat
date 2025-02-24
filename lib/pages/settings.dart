import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _dbPathController = TextEditingController();
  final _oaiKeyController = TextEditingController();
  final _geminiKeyController = TextEditingController();

  static const String _dbPathKey = 'db_path';
  static const String _oaiKey = 'openai_api_key';
  static const String _geminiKey = 'gemini_api_key';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dbPathController.text = prefs.getString(_dbPathKey) ?? '';
      _oaiKeyController.text = prefs.getString(_oaiKey) ?? '';
      _geminiKeyController.text = prefs.getString(_geminiKey) ?? '';
    });
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_dbPathKey, _dbPathController.text);
      await prefs.setString(_oaiKey, _oaiKeyController.text);
      await prefs.setString(_geminiKey, _geminiKeyController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }
    }
  }

  @override
  void dispose() {
    _dbPathController.dispose();
    _oaiKeyController.dispose();
    _geminiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _dbPathController,
                decoration: const InputDecoration(
                  labelText: 'Database Path',
                  hintText: 'Enter path to SQLite database file',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _oaiKeyController,
                decoration: const InputDecoration(
                  labelText: 'OpenAI API Key',
                  hintText: 'Enter your OpenAI API key',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _geminiKeyController,
                decoration: const InputDecoration(
                  labelText: 'Gemini API Key',
                  hintText: 'Enter your Gemini API key',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveSettings,
                child: const Text('Save Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
