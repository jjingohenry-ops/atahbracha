import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../farms/farms_screen.dart';
import '../marketing/marketing_screen.dart';
import '../reminders/reminders_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _biometricEnabled = false;
  bool _notificationsEnabled = true;

  static const _primary = Color(0xFF13EC5B);
  static const _dark = Color(0xFF102216);

  Uint8List? _decodeAvatar(String? base64Avatar) {
    if (base64Avatar == null || base64Avatar.isEmpty) return null;
    try {
      return base64Decode(base64Avatar);
    } catch (_) {
      return null;
    }
  }

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Consumer2<AuthProvider, SettingsProvider>(
      builder: (context, authProvider, settingsProvider, _) {
        final user = authProvider.user;
        final initials = user != null
            ? '${user.firstName.isNotEmpty ? user.firstName[0] : ''}${user.lastName.isNotEmpty ? user.lastName[0] : ''}'.toUpperCase()
            : '?';
        final avatarBase64 = settingsProvider.getProfileAvatarForUser(user?.id);
        final avatarBytes = _decodeAvatar(avatarBase64);
        final fullName = user?.fullName ?? 'Loading...';
        final email = user?.email ?? '';
        final role = user?.role ?? '';

        return Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/bg2.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFF7FFF9), Color(0xFFE8F9EF)],
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned.fill(
              child: Container(
                color: isDark
                    ? colorScheme.surface.withOpacity(0.68)
                    : Colors.white.withOpacity(0.42),
              ),
            ),
            ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
            // Profile header
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surface.withOpacity(isDark ? 0.9 : 1),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.2)
                        : Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: _primary,
                        backgroundImage: avatarBytes != null ? MemoryImage(avatarBytes) : null,
                        child: avatarBytes == null
                            ? Text(
                                initials,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: _dark,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: InkWell(
                          onTap: () => _pickAndSaveProfileImage(context, settingsProvider, user?.id),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: _dark,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: const Icon(Icons.edit, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (email.isNotEmpty)
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
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
                icon: Icons.photo_camera_outlined,
                title: 'Profile Photo',
                subtitle: 'Update dashboard avatar',
                onTap: () => _pickAndSaveProfileImage(context, settingsProvider, user?.id),
              ),
              _divider(),
              _navTile(
                icon: Icons.location_on_outlined,
                title: 'Farms',
                subtitle: settingsProvider.farmLocations != null
                    ? '${settingsProvider.farmLocations!.length} farm${settingsProvider.farmLocations!.length == 1 ? '' : 's'}'
                    : 'Loading...',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FarmsScreen()),
                  );
                },
              ),
              _divider(),
              _navTile(
                icon: Icons.campaign_outlined,
                title: 'Marketing',
                subtitle: 'Campaigns and promotions',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MarketingScreen()),
                  );
                },
              ),
              _divider(),
              _navTile(
                icon: Icons.event_note_outlined,
                title: 'Reminders',
                subtitle: 'Tasks and alerts',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RemindersScreen()),
                  );
                },
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
                subtitle: settingsProvider.isDarkMode ? 'On' : 'Off',
                value: settingsProvider.isDarkMode,
                onChanged: (v) => settingsProvider.setDarkMode(v),
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
            ),
          ],
        );
      },
    );
  }

  Widget _sectionHeader(String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface.withOpacity(0.6),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _settingsGroup(List<Widget> children) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(theme.brightness == Brightness.dark ? 0.9 : 1),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? Colors.black.withOpacity(0.16)
                : Colors.black.withOpacity(0.04),
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
    final colorScheme = Theme.of(context).colorScheme;
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
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.62)))
          : null,
      trailing: Icon(Icons.chevron_right, color: colorScheme.onSurface.withOpacity(0.5)),
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
    final colorScheme = Theme.of(context).colorScheme;
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
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.62)))
          : null,
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

  Future<void> _pickAndSaveProfileImage(
    BuildContext context,
    SettingsProvider settingsProvider,
    String? userId,
  ) async {
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to set a profile photo.')),
      );
      return;
    }

    try {
      final imagePicker = ImagePicker();
      final picked = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 720,
      );

      if (picked == null) {
        return;
      }

      final bytes = await picked.readAsBytes();
      final encoded = base64Encode(bytes);

      await settingsProvider.setProfileAvatarForUser(
        userId: userId,
        base64Image: encoded,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update profile photo.')),
      );
    }
  }

  Future<void> _showUpdateFarmLocationDialog(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) async {
    if (settingsProvider.farmLocations == null) {
      await settingsProvider.fetchFarmLocations();
    }

    final farms = (settingsProvider.farmLocations ?? [])
        .whereType<Map>()
        .map((farm) => Map<String, dynamic>.from(farm))
        .toList();

    String selectedFarmId = farms.isNotEmpty
        ? (farms.first['id']?.toString() ?? 'local-default')
        : 'local-default';

    String selectedFarmName = farms.isNotEmpty
        ? (farms.first['name']?.toString() ?? 'Main Farm')
        : 'Main Farm';

    final controller = TextEditingController(
      text: farms.isNotEmpty ? (farms.first['location']?.toString() ?? '') : '',
    );

    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Update Farm Location'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (farms.length > 1)
                      DropdownButtonFormField<String>(
                        value: selectedFarmId,
                        decoration: const InputDecoration(
                          labelText: 'Farm',
                          border: OutlineInputBorder(),
                        ),
                        items: farms.map((farm) {
                          final id = farm['id']?.toString() ?? 'local-default';
                          final name = farm['name']?.toString() ?? 'Main Farm';
                          return DropdownMenuItem<String>(
                            value: id,
                            child: Text(name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          final selectedFarm = farms.firstWhere(
                            (farm) => farm['id']?.toString() == value,
                            orElse: () => farms.first,
                          );

                          setDialogState(() {
                            selectedFarmId = value;
                            selectedFarmName = selectedFarm['name']?.toString() ?? 'Main Farm';
                            controller.text = selectedFarm['location']?.toString() ?? '';
                          });
                        },
                      )
                    else
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          selectedFarmName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: controller,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        hintText: 'Enter farm location',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Location is required';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() != true) return;
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true) {
      await settingsProvider.updateFarmLocation(
        farmId: selectedFarmId,
        location: controller.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location updated for $selectedFarmName.')),
      );
    }
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
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }
}

