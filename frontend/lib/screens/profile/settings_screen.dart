import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _biometricLogin = true;
  bool _darkMode = false;
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        
        return Scaffold(
          backgroundColor: const Color(0xFFF6F8F6),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              'Settings',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: user == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Section
                      _buildProfileSection(user!),
                      
                      const SizedBox(height: 24),
                      
                      // Account & Profile Section
                      _buildAccountSection(),
                      
                      const SizedBox(height: 24),
                      
                      // Security Section
                      _buildSecuritySection(),
                      
                      const SizedBox(height: 24),
                      
                      // App Preferences Section
                      _buildPreferencesSection(),
                      
                      const SizedBox(height: 24),
                      
                      // Support Section
                      _buildSupportSection(),
                      
                      const SizedBox(height: 32),
                      
                      // Version Info
                      Center(
                        child: Text(
                          'Version 2.4.0 (Build 108)',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[400],
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildProfileSection(dynamic user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF13EC5B).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF13EC5B).withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          // Profile Avatar
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[300],
                  border: Border.all(
                    color: const Color(0xFF13EC5B),
                    width: 2,
                  ),
                ),
                child: user.photoURL != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: Image.network(
                          user.photoURL!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.grey[600],
                      ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13EC5B),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.edit,
                    size: 16,
                    color: Color(0xFF102216),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(width: 16),
          
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName ?? 'User',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF102216),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13EC5B),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Premium',
                    style: TextStyle(
                      color: Color(0xFF102216),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return _buildSettingsSection(
      'Account & Profile',
      [
        _buildSettingsItem(
          icon: Icons.person,
          title: 'Personal Information',
          iconColor: const Color(0xFF13EC5B),
          onTap: () {},
        ),
        _buildSettingsItem(
          icon: Icons.location_on,
          title: 'Farm Locations',
          iconColor: const Color(0xFF13EC5B),
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildSecuritySection() {
    return _buildSettingsSection(
      'Security',
      [
        _buildSettingsItem(
          icon: Icons.fingerprint,
          title: 'Biometric Login',
          iconColor: const Color(0xFF13EC5B),
          trailing: Switch(
            value: _biometricLogin,
            onChanged: (value) {
              setState(() {
                _biometricLogin = value;
              });
            },
            activeColor: const Color(0xFF13EC5B),
          ),
        ),
        _buildSettingsItem(
          icon: Icons.lock,
          title: 'Two-Factor Authentication',
          iconColor: const Color(0xFF13EC5B),
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildPreferencesSection() {
    return _buildSettingsSection(
      'App Preferences',
      [
        _buildSettingsItem(
          icon: Icons.notifications,
          title: 'Notifications',
          iconColor: const Color(0xFF13EC5B),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'All Enabled',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ),
        ),
        _buildSettingsItem(
          icon: Icons.language,
          title: 'Language',
          iconColor: const Color(0xFF13EC5B),
          trailing: Row(
            children: [
              Text(
                'English (US)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
        _buildSettingsItem(
          icon: Icons.dark_mode,
          title: 'Dark Mode',
          iconColor: const Color(0xFF13EC5B),
          trailing: Switch(
            value: _darkMode,
            onChanged: (value) {
              setState(() {
                _darkMode = value;
              });
            },
            activeColor: const Color(0xFF13EC5B),
          ),
        ),
      ],
    );
  }

  Widget _buildSupportSection() {
    return _buildSettingsSection(
      'Support',
      [
        _buildSettingsItem(
          icon: Icons.help,
          title: 'Help Center',
          iconColor: const Color(0xFF13EC5B),
          trailing: Icon(
            Icons.open_in_new,
            size: 16,
            color: Colors.grey[400],
          ),
          onTap: () {},
        ),
        _buildSettingsItem(
          icon: Icons.logout,
          title: 'Sign Out',
          iconColor: Colors.red,
          onTap: () => _showLogoutDialog(context),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF13EC5B),
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[200]!,
            ),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required Color iconColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF102216),
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ] else ...[
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Provider.of<AuthProvider>(context, listen: false).signOut();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
