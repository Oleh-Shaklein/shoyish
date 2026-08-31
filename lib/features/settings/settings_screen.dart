import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLanguage = 'Українська';
  String _aiLanguage = 'Українська (як в інтерфейсі)';
  bool _isDarkMode = false;
  bool _aiVoiceHints = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Налаштування'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Розділ: Інтерфейс та мова
          const Text(
            'ЗАГАЛЬНІ',
            style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language, color: Colors.orange),
                  title: const Text('Мова інтерфейсу'),
                  subtitle: Text(_selectedLanguage),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showLanguageDialog(
                      context,
                      title: 'Мова інтерфейсу',
                      currentValue: _selectedLanguage,
                      onSelected: (val) => setState(() => _selectedLanguage = val),
                    );
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode, color: Colors.orange),
                  title: const Text('Темна тема карти/додатка'),
                  value: _isDarkMode,
                  onChanged: (val) {
                    setState(() {
                      _isDarkMode = val;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Розділ: Параметри ШІ-асистента
          const Text(
            'ШТУЧНИЙ ІНТЕЛЕКТ',
            style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                // Новий елемент: мова відповідей ШІ
                ListTile(
                  leading: const Icon(Icons.auto_awesome, color: Colors.orange),
                  title: const Text('Мова відповідей ШІ'),
                  subtitle: Text(_aiLanguage),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showLanguageDialog(
                      context,
                      title: 'Мова відповідей ШІ',
                      currentValue: _aiLanguage,
                      onSelected: (val) => setState(() => _aiLanguage = val),
                    );
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.record_voice_over, color: Colors.orange),
                  title: const Text('Голосові підказки ШІ'),
                  subtitle: const Text('Озвучувати знахідки та поради'),
                  value: _aiVoiceHints,
                  onChanged: (val) {
                    setState(() {
                      _aiVoiceHints = val;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Розділ: Про програму
          const Text(
            'ПРО ПРОЄКТ',
            style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.school, color: Colors.orange),
                  title: Text('MapMenu AI v1.0'),
                  subtitle: Text('Магістерський проєкт: Геопросторовий навігатор із LLM'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: Colors.orange),
                  title: const Text('Використані технології'),
                  subtitle: const Text('Flutter, FlutterMap, OpenStreetMap'),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'MapMenu',
                      applicationVersion: '1.0.0',
                      applicationLegalese: '© 2026 MapMenu Project',
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: Text('Інтерактивна навігаційна система з можливістю контекстного пошуку закладів за допомогою штучного інтелекту.'),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Універсальне вікно вибору мови (і для інтерфейсу, і для ШІ)
  void _showLanguageDialog(
      BuildContext context, {
        required String title,
        required String currentValue,
        required ValueChanged<String> onSelected,
      }) {
    final languages = ['Українська', 'English', 'Polski', 'Deutsch', 'Français'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: languages.map((lang) {
              return RadioListTile<String>(
                title: Text(lang),
                value: lang,
                groupValue: currentValue,
                onChanged: (val) {
                  if (val != null) {
                    onSelected(val);
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}