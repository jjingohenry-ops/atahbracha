import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _biometricEnabled = false;
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  static const _primary = Color(0xFF13EC5B);
  static const _dark = Color(0xFF102216);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SettingsProvider>(context, listen: false).fetchProfile();
      Provider.of<SettingsProvider>(context, listen: false).fetchFarmLocations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, SettingsProvider>(
      builder: (context, authProvider, settingsProvider, _) {
        final user = authProvider.user;
        final initials = user != null
            ? '${user.firstName.isNotEmpty ? user.firstName[0] : ''}${user.lastName.isNotEmpty ? user.lastName[0] : ''}'.toUpperCase()
            : '?';
        final fullName = user?.fullName ?? 'Loading...';
        final email = user?.email ?? '';
        final role = user?.role ?? '';

        return ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            // Profile header
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: _primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: _dark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _dark,
                          ),
                        ),
                        if (email.isNotEmpty)
                          Text(
                            email,
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (role.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  role[0].toUpperCase() + role.substring(1).toLowerCase(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _dark,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD700).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star_rounded, size: 12, color: Color(0xFFFFAA00)),
                                  SizedBox(width: 3),
                                  Text(
                                    'Premium',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFFFAA00),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Account & Profile
            _sectionHeader('Account & Profile'),
            _settingsGroup([
              _navTile(
                icon: Icons.person_outline,
                title: 'Personal Information',
                subtitle: fullName,
                onTap: () {},
              ),
              _divider(),
              _navTile(
                icon: Icons.location_on_outlined,
                title: 'Farm Locations',
                subtitle: settingsProvider.farmLocations != null
                    ? '${settingsProvider.farmLocations!.length} location${settingsProvider.farmLocations!.length == 1 ? '' : 's'}'
                    : 'Loading...',
                onTap: () {},
              ),
            ]),

            // Security
            _sectionHeader('Security'),
            _settingsGroup([
              _toggleTile(
                icon: Icons.fingerprint,
                title: 'Biometric Login',
                subtitle: 'Use fingerprint or Face ID',
                value: _biometricEnabled,
                onChanged: (v) => setState(() => _biometricEnabled = v),
              ),
              _divider(),
              _navTile(
                icon: Icons.shield_outlined,
                title: 'Two-Factor Authentication',
                subtitle: 'Not enabled',
                onTap: () {},
              ),
            ]),

            // App Preferences
            _sectionHeader('App Preferences'),
            _settingsGroup([
              _toggleTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: _notificationsEnabled ? 'All Enabled' : 'Disabled',
                value: _notificationsEnabled,
                onChanged: (v) => setState(() => _notificationsEnabled = v),
              ),
              _divider(),
              _navTile(
                icon: Icons.language,
                title: 'Language',
                subtitle: 'English (US)',
                onTap: () {},
              ),
              _divider(),
              _toggleTile(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                subtitle: _darkModeEnabled ? 'On' : 'Off',
                value: _darkModeEnabled,
                onChanged: (v) => setState(() => _darkModeEnabled = v),
              ),
            ]),

            // Support
            _sectionHeader('Support'),
            _settingsGroup([
              _navTile(
                icon: Icons.help_outline,
                title: 'Help Center',
                onTap: () {},
              ),
              _divider(),
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.logout, color: Colors.red, size: 20),
                ),
                title: const Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.red),
                onTap: () => _confirmSignOut(context, authProvider),
              ),
            ]),

            // Version footer
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Version 2.4.0 (Build 108)',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey[500],
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _settingsGroup(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _navTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: _dark, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _dark)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])) : null,
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
    );
  }

  Widget _toggleTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: _dark, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _dark)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])) : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: _primary,
        activeTrackColor: _primary.withOpacity(0.35),
      ),
    );
  }

  Widget _divider() {
    return const Divider(height: 1, indent: 56, endIndent: 16);
  }

  Future<void> _confirmSignOut(BuildContext context, AuthProvider authProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await authProvider.signOut();
    }
  }
}

