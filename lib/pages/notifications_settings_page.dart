import 'package:flutter/material.dart';

class NotificationsSettingsPage extends StatefulWidget {
  const NotificationsSettingsPage({super.key});

  @override
  State<NotificationsSettingsPage> createState() => _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage> {
  bool _dailyReminder = true;
  bool _achievementNotifications = true;
  bool _practiceReminder = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 18, minute: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Oznámení'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSwitchTile(
            title: 'Denní připomínka',
            subtitle: 'Připomenutí k pravidelnému cvičení',
            value: _dailyReminder,
            onChanged: (value) => setState(() => _dailyReminder = value),
          ),
          
          if (_dailyReminder)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 16),
              child: ListTile(
                title: const Text('Čas připomínky'),
                subtitle: Text(_reminderTime.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _reminderTime,
                  );
                  if (time != null) {
                    setState(() => _reminderTime = time);
                  }
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: Theme.of(context).colorScheme.surfaceVariant,
              ),
            ),

          _buildSwitchTile(
            title: 'Oznámení o úspěších',
            subtitle: 'Upozornění na nové odznaky a milníky',
            value: _achievementNotifications,
            onChanged: (value) => setState(() => _achievementNotifications = value),
          ),

          _buildSwitchTile(
            title: 'Připomínka cvičení',
            subtitle: 'Upozornění pokud jsi dnes necvičil',
            value: _practiceReminder,
            onChanged: (value) => setState(() => _practiceReminder = value),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Nastavení uloženo'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Uložit',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.2),
          ),
        ),
        child: SwitchListTile(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(subtitle),
          value: value,
          onChanged: onChanged,
          activeColor: Theme.of(context).primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}