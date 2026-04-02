import 'package:aarvi_cinema/btm_profile_sc.dart';
import 'package:flutter/material.dart';

class SettingsMenuScreen extends StatelessWidget {
  const SettingsMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings"), centerTitle: true),
      body: ListView(
        children: [
          const SizedBox(height: 20),

          // -------- PROFILE SECTION --------
          ListTile(
            leading: const Icon(Icons.person_outline, color: Colors.blue),
            title: const Text("Profile"),
            subtitle: const Text("Edit your profile & account details"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BtmProfileSc()),
              );
            },
          ),
          const Divider(),

          // -------- APP PREFERENCES --------
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "App Preferences",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language, color: Colors.orange),
            title: const Text("Language"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to Language selection screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.location_on_outlined, color: Colors.red),
            title: const Text("Default City"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to City selection screen
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.color_lens_outlined,
              color: Colors.purple,
            ),
            title: const Text("Theme"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to Theme selection screen
            },
          ),
          const Divider(),

          // -------- NOTIFICATIONS --------
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "Notifications",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          SwitchListTile(
            title: const Text("Movie Alerts"),
            value: true,
            onChanged: (value) {
              // Toggle movie alerts
            },
          ),
          SwitchListTile(
            title: const Text("Booking Notifications"),
            value: true,
            onChanged: (value) {
              // Toggle booking notifications
            },
          ),
          SwitchListTile(
            title: const Text("Offers & Promotions"),
            value: false,
            onChanged: (value) {
              // Toggle offers notifications
            },
          ),
          const Divider(),

          // -------- LEGAL --------
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "Legal",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.description_outlined,
              color: Colors.green,
            ),
            title: const Text("Terms & Conditions"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Open Terms & Conditions
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined, color: Colors.teal),
            title: const Text("Privacy Policy"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Open Privacy Policy
            },
          ),
          const Divider(),

          // -------- LOGOUT --------
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout"),
            onTap: () {
              // Show logout confirmation
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Logout"),
                  content: const Text(
                    "Are you sure you want to logout from the app?",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Add logout logic here
                      },
                      child: const Text("Logout"),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // App version
          const Center(
            child: Text(
              "App Version 1.0.0",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
