import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Settings'),
        backgroundColor: Colors.green.shade900,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.center,
            colors: [
              Colors.green.shade900,
              Colors.grey.shade900,
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Support Section
            _buildSectionHeader('Support'),
            _buildListTile(
              title: 'Subscriptions',
              subtitle: 'Manage your subscriptions',
              icon: Icons.payment,
              onTap: () {
                // Navigate to subscriptions screen
                _showFeatureNotImplementedDialog('Subscriptions');
              },
            ),
            _buildListTile(
              title: 'Privacy Policy',
              subtitle: 'Read our privacy policy',
              icon: Icons.privacy_tip,
              onTap: () {
                // Navigate to privacy policy
                _showFeatureNotImplementedDialog('Privacy Policy');
              },
            ),
            _buildListTile(
              title: 'Share App',
              subtitle: 'Share with friends',
              icon: Icons.share,
              onTap: _shareApp,
            ),
            _buildListTile(
              title: 'Support',
              subtitle: 'Get help and support',
              icon: Icons.support,
              onTap: () {
                // Navigate to support screen
                _showFeatureNotImplementedDialog('Support');
              },
            ),
            _buildListTile(
              title: 'Terms & Conditions',
              subtitle: 'Read terms and conditions',
              icon: Icons.description,
              onTap: () {
                // Navigate to terms and conditions
                _showFeatureNotImplementedDialog('Terms & Conditions');
              },
            ),
            
            const SizedBox(height: 20),
            
            // About Section
            _buildSectionHeader('About'),
            _buildListTile(
              title: 'Rate App',
              subtitle: 'Rate us on app store',
              icon: Icons.star,
              onTap: () {
                // Navigate to app rating
                _showFeatureNotImplementedDialog('Rate App');
              },
            ),
            _buildListTile(
              title: 'Version',
              subtitle: '1.0.0',
              icon: Icons.info,
              onTap: null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Card(
      color: Colors.grey.shade800,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.greenAccent),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.grey),
        ),
        trailing: onTap != null
            ? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey)
            : null,
        onTap: onTap,
      ),
    );
  }

  void _shareApp() async {
    // Simple share functionality
    final String appLink = 'https://play.google.com/store/apps/details?id=com.example.wallpapers';
    final String shareText = 'Check out this amazing wallpaper app! $appLink';
    
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Share App'),
          content: Text(shareText),
          backgroundColor: Colors.grey.shade900,
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          contentTextStyle: const TextStyle(color: Colors.white),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                // In a real app, you would use a share package here
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('App link copied to clipboard!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Copy Link'),
            ),
          ],
        );
      },
    );
  }

  void _showFeatureNotImplementedDialog(String featureName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Feature Not Available'),
          content: Text('$featureName feature is not implemented yet.'),
          backgroundColor: Colors.grey.shade900,
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          contentTextStyle: const TextStyle(color: Colors.white),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}