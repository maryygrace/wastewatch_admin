import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wastewatch_admin/providers/theme_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Account'),
            subtitle: Text(Supabase.instance.client.auth.currentUser?.email ?? 'No user logged in'),
          ),
          const Divider(),
          ExpansionTile(
            leading: const Icon(Icons.settings),
            title: const Text('App Settings'),
            children: [
              SwitchListTile(
                title: const Text('Enable Dark Mode'),
                value: themeProvider.isDarkMode(context),
                onChanged: (bool value) => themeProvider.toggleTheme(value),
                secondary: const Icon(Icons.brightness_6),
              ),
            ],
          ),
          const Divider(),
        ],
      ),
    );
  }
}