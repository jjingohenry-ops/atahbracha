import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/animals_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/reminders_provider.dart';
import '../../providers/settings_provider.dart';
import '../ai/ai_chat_screen.dart';
import '../animals/add_animal_modal.dart';
import '../animals/animals_screen.dart';
import '../auth/login_screen.dart';
import '../marketing/marketing_screen.dart';
import '../reminders/reminders_screen.dart';
import '../settings/settings_screen.dart';
import 'dashboard_tab.dart';

class HomeScreen extends StatefulWidget {
  final int initialTabIndex;

  const HomeScreen({super.key, this.initialTabIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTabIndex = 0;
  bool _farmOnboardingShown = false;

  List<Map<String, dynamic>> _farmOptions(SettingsProvider settingsProvider) {
    return (settingsProvider.farmLocations ?? [])
        .whereType<Map>()
        .map((Map farm) => Map<String, dynamic>.from(farm))
        .where((Map<String, dynamic> farm) {
          final String id = farm['id']?.toString() ?? '';
          return id.isNotEmpty;
        })
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex.clamp(0, 4);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) return;

    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    await settingsProvider.fetchFarmLocations();
    if (!mounted) return;

    final hasFarm = await _ensureFarmOnboarding();
    if (!mounted || !hasFarm) return;

    await _refreshFarmScopedData();
  }

  Future<bool> _ensureFarmOnboarding() async {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );

    // If farm loading failed, do not force onboarding; the issue is likely auth/API related.
    if (settingsProvider.error != null && settingsProvider.error!.isNotEmpty) {
      return false;
    }

    final farms = (settingsProvider.farmLocations ?? [])
        .whereType<Map>()
        .map((farm) => Map<String, dynamic>.from(farm))
        .where((farm) => (farm['id']?.toString() ?? '').isNotEmpty)
        .toList();

    if (farms.isNotEmpty) {
      return true;
    }

    if (_farmOnboardingShown) {
      return false;
    }

    _farmOnboardingShown = true;
    final created = await _showCreateFarmRequiredModal();
    _farmOnboardingShown = false;

    if (created) {
      await settingsProvider.fetchFarmLocations();
      final refreshedFarms = (settingsProvider.farmLocations ?? [])
          .whereType<Map>()
          .where((farm) => (farm['id']?.toString() ?? '').isNotEmpty)
          .toList();
      return refreshedFarms.isNotEmpty;
    }

    return false;
  }

  Future<bool> _showCreateFarmRequiredModal() async {
    final rootContext = context;
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    bool isSaving = false;
    String? dialogError;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (modalContext, setDialogState) {
            return AlertDialog(
              title: const Text('Set Up Your First Farm'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Create a farm to start loading your dashboard and animal data.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Farm Name *',
                      hintText: 'My Main Farm',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location (optional)',
                    ),
                  ),
                  if (dialogError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      dialogError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (Navigator.of(dialogContext).canPop()) {
                            Navigator.of(dialogContext).pop(false);
                          }
                          await Provider.of<AuthProvider>(
                            rootContext,
                            listen: false,
                          ).signOut();
                        },
                  child: const Text('Sign Out'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final farmName = nameController.text.trim();
                          if (farmName.isEmpty) {
                            setDialogState(
                              () => dialogError = 'Farm name is required',
                            );
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                            dialogError = null;
                          });

                          final settingsProvider =
                              Provider.of<SettingsProvider>(
                                rootContext,
                                listen: false,
                              );
                          final success = await settingsProvider.createFarm(
                            name: farmName,
                            location: locationController.text.trim(),
                          );

                          if (!mounted || !dialogContext.mounted) return;

                          if (success) {
                            Navigator.of(dialogContext).pop(true);
                          } else {
                            setDialogState(() {
                              isSaving = false;
                              dialogError =
                                  settingsProvider.error ??
                                  'Failed to create farm';
                            });
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Farm'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    locationController.dispose();

    return result == true;
  }

  Future<void> _refreshFarmScopedData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) return;

    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final dashboardProvider = Provider.of<DashboardProvider>(
      context,
      listen: false,
    );
    final animalsProvider = Provider.of<AnimalsProvider>(
      context,
      listen: false,
    );
    final remindersProvider = Provider.of<RemindersProvider>(
      context,
      listen: false,
    );

    final farmId = settingsProvider.activeFarmId;

    await dashboardProvider.fetchDashboardData(farmId: farmId);
    await animalsProvider.fetchAnimals(farmId: farmId);

    final targetDate = remindersProvider.selectedDate ?? DateTime.now();
    await remindersProvider.fetchReminders(date: targetDate, farmId: farmId);
  }

  Future<void> _onFarmChanged(String? farmId) async {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    await settingsProvider.selectActiveFarm(farmId);
    if (!mounted) return;
    await _refreshFarmScopedData();
  }

  Uint8List? _decodeAvatar(String? base64Avatar) {
    if (base64Avatar == null || base64Avatar.isEmpty) return null;
    try {
      return base64Decode(base64Avatar);
    } catch (_) {
      return null;
    }
  }

  List<Widget> _buildTabs() {
    return [
      DashboardTab(onFarmChanged: _onFarmChanged),
      const AnimalsScreen(),
      const RemindersScreen(),
      const MarketingScreen(),
      const SettingsScreen(),
    ];
  }

  Widget _buildTopFarmDropdown(SettingsProvider settingsProvider) {
    final farms = _farmOptions(settingsProvider);
    final selectedFarmId = settingsProvider.activeFarmId;
    final selectedFarmName = settingsProvider.activeFarm?['name']?.toString();

    if (farms.isEmpty) {
      return Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0x66FFFFFF),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0x55FFFFFF), width: 0.6),
        ),
        alignment: Alignment.centerLeft,
        child: const Text(
          'No farms',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF234B8D),
          ),
        ),
      );
    }

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0x66FFFFFF),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0x55FFFFFF), width: 0.6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedFarmId,
          hint: Text(
            selectedFarmName ?? 'Select farm',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF234B8D),
            ),
          ),
          icon: const Icon(
            Icons.arrow_drop_down,
            color: Color(0xFF234B8D),
            size: 16,
          ),
          dropdownColor: const Color(0xFFDDBFC7),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF234B8D),
          ),
          items: farms
              .map(
                (Map<String, dynamic> farm) => DropdownMenuItem<String>(
                  value: farm['id']?.toString(),
                  child: Text(farm['name']?.toString() ?? 'Unnamed Farm'),
                ),
              )
              .toList(),
          onChanged: (String? value) async {
            await _onFarmChanged(value);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, SettingsProvider>(
      builder: (context, authProvider, settingsProvider, child) {
        final user = authProvider.user;
        final initials = user == null
            ? '?'
            : '${user.firstName.isNotEmpty ? user.firstName[0] : ''}${user.lastName.isNotEmpty ? user.lastName[0] : ''}'
                  .toUpperCase();
        final avatarBytes = _decodeAvatar(
          settingsProvider.getProfileAvatarForUser(user?.id),
        );

        return Scaffold(
          backgroundColor: const Color(0xFFF6F8F6),
          extendBody: true,
          body: user == null
              ? const LoginScreen()
              : Column(
                  children: [
                    if (_selectedTabIndex != 0)
                      SafeArea(
                        bottom: false,
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                          padding: const EdgeInsets.fromLTRB(9, 3, 9, 3),
                          decoration: BoxDecoration(
                            color: const Color(0xCCDDBFC7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0x66FFFFFF),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 13,
                                backgroundColor: const Color(0xFF13EC5B),
                                backgroundImage: avatarBytes != null
                                    ? MemoryImage(avatarBytes)
                                    : null,
                                child: avatarBytes == null
                                    ? Text(
                                        initials.isEmpty ? '?' : initials,
                                        style: const TextStyle(
                                          color: Color(0xFF102216),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getTabTitle(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF234B8D),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildTopFarmDropdown(settingsProvider),
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.notifications,
                                  color: Color(0xFF234B8D),
                                ),
                                iconSize: 18,
                                constraints: const BoxConstraints.tightFor(
                                  width: 28,
                                  height: 28,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ),
                      ),
                    Expanded(
                      child: IndexedStack(
                        index: _selectedTabIndex,
                        children: _buildTabs(),
                      ),
                    ),
                  ],
                ),
          floatingActionButton: _selectedTabIndex == 1
              ? FloatingActionButton(
                  onPressed: () async {
                    final saved = await showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const AddAnimalModal(),
                    );

                    if (!mounted || saved != true) return;
                    await Provider.of<AnimalsProvider>(
                      context,
                      listen: false,
                    ).fetchAnimals(farmId: settingsProvider.activeFarmId);
                  },
                  backgroundColor: const Color(0xFF13EC5B),
                  foregroundColor: Colors.black87,
                  child: const Icon(Icons.add),
                )
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: _buildBottomNavigationBar(),
        );
      },
    );
  }

  String _getTabTitle() {
    const titles = ['Dashboard', 'Animals', 'Alerts', 'Reports', 'Profile'];
    return titles[_selectedTabIndex];
  }

  Widget _buildBottomNavigationBar() {
    const labels = ['Dashboard', 'Animals', 'Alerts', 'Reports', 'Profile'];
    const icons = [
      Icons.pets,
      Icons.cruelty_free,
      Icons.pest_control,
      Icons.egg_alt,
      Icons.pets_outlined,
    ];
    const baseColors = [
      Color(0xFF0B2D70),
      Color(0xFF1F3A75),
      Color(0xFFD33131),
      Color(0xFF2B5FB8),
      Color(0xFF234B8D),
    ];

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 6),
        padding: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xCCDDBFC7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x66FFFFFF), width: 0.5),
        ),
        child: Row(
          children: List<Widget>.generate(labels.length, (int index) {
            final bool isSelected = _selectedTabIndex == index;
            final Color itemColor = isSelected
                ? baseColors[index]
                : baseColors[index].withOpacity(0.82);

            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedTabIndex = index;
                        });

                        if (index == 0) {
                          _refreshFarmScopedData();
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icons[index], size: 18, color: itemColor),
                            const SizedBox(height: 1),
                            Text(
                              labels[index],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w700,
                                color: itemColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (index < labels.length - 1)
                    Container(
                      width: 1,
                      height: 20,
                      color: const Color(0x704E5B75),
                    ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
