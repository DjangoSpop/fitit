import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _notificationFrequency = 'moderate';
  TimeOfDay _preferredWorkoutTime = TimeOfDay(hour: 18, minute: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.all(AppTheme.spaceMD),
        children: [
          _buildSectionHeader('Preferences'),
          _buildSettingsCard(
            children: [
              _buildSwitchTile(
                'Dark Mode',
                'Switch between light and dark theme',
                Icons.dark_mode,
                _darkModeEnabled,
                (value) => setState(() => _darkModeEnabled = value),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spaceLG),
          _buildSectionHeader('Notifications'),
          _buildSettingsCard(
            children: [
              _buildSwitchTile(
                'Enable Notifications',
                'Receive workout reminders and motivation',
                Icons.notifications_active,
                _notificationsEnabled,
                (value) => setState(() => _notificationsEnabled = value),
              ),
              if (_notificationsEnabled) ...[
                Divider(height: 1),
                _buildNotificationFrequencyTile(),
                Divider(height: 1),
                _buildPreferredTimeTile(),
              ],
            ],
          ),
          SizedBox(height: AppTheme.spaceLG),
          _buildSectionHeader('Habit Tracking'),
          _buildSettingsCard(
            children: [
              _buildNavigationTile(
                'Habit Preferences',
                'Customize your tracked habits',
                Icons.checklist,
                () {},
              ),
              Divider(height: 1),
              _buildNavigationTile(
                'Weekly Goals',
                'Set your weekly targets',
                Icons.flag,
                () {},
              ),
            ],
          ),
          SizedBox(height: AppTheme.spaceLG),
          _buildSectionHeader('Data & Privacy'),
          _buildSettingsCard(
            children: [
              _buildNavigationTile(
                'Export Data',
                'Download your fitness data',
                Icons.download,
                () {},
              ),
              Divider(height: 1),
              _buildNavigationTile(
                'Privacy Policy',
                'Read our privacy policy',
                Icons.privacy_tip,
                () {},
              ),
            ],
          ),
          SizedBox(height: AppTheme.spaceLG),
          _buildSectionHeader('About'),
          _buildSettingsCard(
            children: [
              _buildInfoTile('Version', '2.0.0'),
              Divider(height: 1),
              _buildNavigationTile(
                'Help & Support',
                'Get help with the app',
                Icons.help_outline,
                () {},
              ),
            ],
          ),
          SizedBox(height: AppTheme.space2XL),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spaceXS,
        bottom: AppTheme.spaceSM,
        top: AppTheme.spaceSM,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryPurple,
            ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Card(
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(AppTheme.spaceSM),
        decoration: BoxDecoration(
          color: AppTheme.primaryPurple.withOpacity(0.1),
          borderRadius: AppTheme.smallRadius,
        ),
        child: Icon(icon, color: AppTheme.primaryPurple),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryPurple,
      ),
    );
  }

  Widget _buildNavigationTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(AppTheme.spaceSM),
        decoration: BoxDecoration(
          color: AppTheme.primaryPurple.withOpacity(0.1),
          borderRadius: AppTheme.smallRadius,
        ),
        child: Icon(icon, color: AppTheme.primaryPurple),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.chevron_right, color: AppTheme.textGrey),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      trailing: Text(
        value,
        style: TextStyle(color: AppTheme.textGrey),
      ),
    );
  }

  Widget _buildNotificationFrequencyTile() {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(AppTheme.spaceSM),
        decoration: BoxDecoration(
          color: AppTheme.primaryPurple.withOpacity(0.1),
          borderRadius: AppTheme.smallRadius,
        ),
        child: Icon(Icons.tune, color: AppTheme.primaryPurple),
      ),
      title: Text(
        'Notification Frequency',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(_getFrequencyLabel(_notificationFrequency)),
      trailing: Icon(Icons.chevron_right, color: AppTheme.textGrey),
      onTap: () => _showFrequencyDialog(),
    );
  }

  Widget _buildPreferredTimeTile() {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(AppTheme.spaceSM),
        decoration: BoxDecoration(
          color: AppTheme.primaryPurple.withOpacity(0.1),
          borderRadius: AppTheme.smallRadius,
        ),
        child: Icon(Icons.access_time, color: AppTheme.primaryPurple),
      ),
      title: Text(
        'Preferred Workout Time',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(_preferredWorkoutTime.format(context)),
      trailing: Icon(Icons.chevron_right, color: AppTheme.textGrey),
      onTap: () => _selectTime(),
    );
  }

  String _getFrequencyLabel(String frequency) {
    switch (frequency) {
      case 'low':
        return 'Once per day';
      case 'moderate':
        return '2-3 times per day';
      case 'high':
        return '4+ times per day';
      default:
        return 'Moderate';
    }
  }

  void _showFrequencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Notification Frequency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text('Low'),
              subtitle: Text('Once per day'),
              value: 'low',
              groupValue: _notificationFrequency,
              onChanged: (value) {
                setState(() => _notificationFrequency = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: Text('Moderate'),
              subtitle: Text('2-3 times per day'),
              value: 'moderate',
              groupValue: _notificationFrequency,
              onChanged: (value) {
                setState(() => _notificationFrequency = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: Text('High'),
              subtitle: Text('4+ times per day'),
              value: 'high',
              groupValue: _notificationFrequency,
              onChanged: (value) {
                setState(() => _notificationFrequency = value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _preferredWorkoutTime,
    );

    if (picked != null && picked != _preferredWorkoutTime) {
      setState(() {
        _preferredWorkoutTime = picked;
      });
    }
  }
}
