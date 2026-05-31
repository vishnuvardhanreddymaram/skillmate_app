import 'package:flutter/material.dart';
import 'account_details_screen.dart';
import 'change_password_screen.dart';
import 'notification_settings_screen.dart';
import 'privacy_settings_screen.dart';
import 'language_screen.dart';
import 'blocked_users_screen.dart';
import 'help_support_screen.dart';
import 'faq_screen.dart';
import 'about_us_screen.dart';
import 'safety_tips_screen.dart';
import 'user_guide_screen.dart';
import 'developer_credits_screen.dart';

class SettingsDashboardScreen extends StatelessWidget {
  const SettingsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          _buildCategory("Account"),
          _buildItem(context, "Account Details", Icons.person, const AccountDetailsScreen()),
          _buildItem(context, "Change Password", Icons.lock, const ChangePasswordScreen()),
          _buildItem(context, "Privacy Settings", Icons.privacy_tip, const PrivacySettingsScreen()),
          
          _buildCategory("Preferences"),
          _buildItem(context, "Notifications", Icons.notifications, const NotificationSettingsScreen()),
          _buildItem(context, "Language", Icons.language, const LanguageScreen()),
          _buildItem(context, "Blocked Users", Icons.block, const BlockedUsersScreen()),

          _buildCategory("Guides & Safety"),
          _buildItem(context, "Safety Tips", Icons.security, const SafetyTipsScreen()),
          _buildItem(context, "User Guide", Icons.menu_book, const UserGuideScreen()),

          _buildCategory("Support & Info"),
          _buildItem(context, "Help & Support", Icons.help, const HelpSupportScreen()),
          _buildItem(context, "FAQ", Icons.question_answer, const FAQScreen()),
          _buildItem(context, "About Us", Icons.info, const AboutUsScreen()),
          _buildItem(context, "Developer Credits", Icons.code, const DeveloperCreditsScreen()),
        ],
      ),
    );
  }

  Widget _buildCategory(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6C63FF))),
    );
  }

  Widget _buildItem(BuildContext context, String title, IconData icon, Widget screen) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      },
    );
  }
}
