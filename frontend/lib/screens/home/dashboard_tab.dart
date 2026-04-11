import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/animals_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/reminders_provider.dart';
import '../../providers/settings_provider.dart';
import '../ai/ai_chat_screen.dart';
import '../animals/add_animal_modal.dart';
import '../reminders/reminders_screen.dart';

class DashboardTab extends StatefulWidget {
  final Future<void> Function(String?)? onFarmChanged;

  const DashboardTab({super.key, this.onFarmChanged});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  bool _isRefreshing = false;

  static const List<Color> _cardColors = <Color>[
    Color(0xFF2EAD57),
    Color(0xFFF39A1E),
    Color(0xFFCF2E2E),
    Color(0xFF2D63C9),
  ];

  static const List<Color> _cardAccentColors = <Color>[
    Color(0xFF7BDA9B),
    Color(0xFFFCC66A),
    Color(0xFFF38B8B),
    Color(0xFF7EA5F3),
  ];

  static const List<Color> _alertColors = <Color>[
    Color(0xFF434F75),
    Color(0xFFD31E1C),
    Color(0xFF302A5A),
    Color(0xFFB78456),
  ];

  static const List<Color> _quickActionColors = <Color>[
    Color(0xFF2EAD57),
    Color(0xFFCF2E2E),
    Color(0xFF2EAD57),
    Color(0xFFF39A1E),
    Color(0xFF2D63C9),
  ];

  bool _isDark(Color color) {
    return ThemeData.estimateBrightnessForColor(color) == Brightness.dark;
  }

  Color _textOn(Color background) {
    return _isDark(background) ? Colors.white : const Color(0xFF042C71);
  }

  Color _mutedTextOn(Color background) {
    return _isDark(background) ? Colors.white70 : const Color(0xFF355393);
  }

  Future<void> _refreshAll() async {
    if (_isRefreshing) {
      return;
    }

    setState(() {
      _isRefreshing = true;
    });

    try {
      final SettingsProvider settingsProvider = Provider.of<SettingsProvider>(
        context,
        listen: false,
      );
      final DashboardProvider dashboardProvider =
          Provider.of<DashboardProvider>(context, listen: false);
      final AnimalsProvider animalsProvider = Provider.of<AnimalsProvider>(
        context,
        listen: false,
      );
      final RemindersProvider remindersProvider =
          Provider.of<RemindersProvider>(context, listen: false);

      final String? farmId = settingsProvider.activeFarmId;
      await Future.wait(<Future<void>>[
        dashboardProvider.fetchDashboardData(farmId: farmId),
        animalsProvider.fetchAnimals(farmId: farmId),
        remindersProvider.fetchReminders(
          farmId: farmId,
        ),
      ]);
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _openAddAnimalModal() async {
    final bool? saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => const AddAnimalModal(),
    );

    if (!mounted || saved != true) {
      return;
    }

    await _refreshAll();
  }

  Future<void> _openAiChat() async {
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<Widget>(
        builder: (_) => const AiChatScreen(),
      ),
    );
  }

  Future<void> _showResultSnack({
    required bool success,
    required String message,
  }) async {
    if (!mounted || message.trim().isEmpty) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success
            ? const Color(0xFF0F8A3F)
            : const Color(0xFFB42318),
      ),
    );
  }

  List<Map<String, String>> _buildAnimalChoices(List<dynamic> animals) {
    return animals
        .whereType<Map>()
        .map(
          (Map<dynamic, dynamic> animal) => <String, String>{
            'id': animal['id']?.toString() ?? '',
            'name': animal['name']?.toString() ?? 'Unnamed',
          },
        )
        .where((Map<String, String> item) => item['id']!.isNotEmpty)
        .toList();
  }

  Future<void> _quickRecordTreatment() async {
    final SettingsProvider settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final AnimalsProvider animalsProvider = Provider.of<AnimalsProvider>(
      context,
      listen: false,
    );
    final DashboardProvider dashboardProvider = Provider.of<DashboardProvider>(
      context,
      listen: false,
    );

    final String? farmId = settingsProvider.activeFarmId;
    if (farmId == null || farmId.isEmpty) {
      await _showResultSnack(
        success: false,
        message: 'Please select a farm first.',
      );
      return;
    }

    final List<Map<String, String>> animalChoices = _buildAnimalChoices(
      animalsProvider.animals,
    );
    if (animalChoices.isEmpty) {
      await _showResultSnack(
        success: false,
        message: 'Add at least one animal before recording treatment.',
      );
      return;
    }

    final TextEditingController drugController = TextEditingController();
    final TextEditingController dosageController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    String selectedAnimalId = animalChoices.first['id']!;
    DateTime selectedDate = DateTime.now();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder:
              (BuildContext context, void Function(void Function()) setState) {
                return AlertDialog(
                  title: const Text('Record Treatment'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        DropdownButtonFormField<String>(
                          value: selectedAnimalId,
                          decoration: const InputDecoration(
                            labelText: 'Animal',
                          ),
                          items: animalChoices
                              .map(
                                (Map<String, String> item) =>
                                    DropdownMenuItem<String>(
                                      value: item['id'],
                                      child: Text(item['name']!),
                                    ),
                              )
                              .toList(),
                          onChanged: (String? value) {
                            if (value == null) {
                              return;
                            }
                            setState(() {
                              selectedAnimalId = value;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: drugController,
                          decoration: const InputDecoration(
                            labelText: 'Drug name',
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: dosageController,
                          decoration: const InputDecoration(
                            labelText: 'Dosage',
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: notesController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Notes (optional)',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            const Text('Date:'),
                            const SizedBox(width: 8),
                            Text(DateFormat('MMM d, y').format(selectedDate)),
                            const Spacer(),
                            TextButton(
                              onPressed: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2100),
                                );
                                if (picked == null) {
                                  return;
                                }
                                setState(() {
                                  selectedDate = picked;
                                });
                              },
                              child: const Text('Change'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Save'),
                    ),
                  ],
                );
              },
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final String drugName = drugController.text.trim();
    final String dosage = dosageController.text.trim();

    if (drugName.isEmpty || dosage.isEmpty) {
      await _showResultSnack(
        success: false,
        message: 'Drug name and dosage are required.',
      );
      return;
    }

    final bool success = await dashboardProvider.recordTreatment(
      farmId: farmId,
      animalId: selectedAnimalId,
      drugName: drugName,
      dosage: dosage,
      date: selectedDate,
      notes: notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim(),
    );

    await _showResultSnack(
      success: success,
      message: success
          ? (dashboardProvider.actionSuccess ?? 'Treatment recorded.')
          : (dashboardProvider.actionError ?? 'Unable to record treatment.'),
    );

    if (success) {
      await _refreshAll();
    }
  }

  Future<void> _quickLogFeeding() async {
    final SettingsProvider settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final AnimalsProvider animalsProvider = Provider.of<AnimalsProvider>(
      context,
      listen: false,
    );
    final DashboardProvider dashboardProvider = Provider.of<DashboardProvider>(
      context,
      listen: false,
    );

    final String? farmId = settingsProvider.activeFarmId;
    if (farmId == null || farmId.isEmpty) {
      await _showResultSnack(
        success: false,
        message: 'Please select a farm first.',
      );
      return;
    }

    final List<Map<String, String>> animalChoices = _buildAnimalChoices(
      animalsProvider.animals,
    );
    if (animalChoices.isEmpty) {
      await _showResultSnack(
        success: false,
        message: 'Add at least one animal before logging feeding.',
      );
      return;
    }

    final TextEditingController foodController = TextEditingController();
    final TextEditingController quantityController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    String selectedAnimalId = animalChoices.first['id']!;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder:
              (BuildContext context, void Function(void Function()) setState) {
                return AlertDialog(
                  title: const Text('Log Feeding'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        DropdownButtonFormField<String>(
                          value: selectedAnimalId,
                          decoration: const InputDecoration(
                            labelText: 'Animal',
                          ),
                          items: animalChoices
                              .map(
                                (Map<String, String> item) =>
                                    DropdownMenuItem<String>(
                                      value: item['id'],
                                      child: Text(item['name']!),
                                    ),
                              )
                              .toList(),
                          onChanged: (String? value) {
                            if (value == null) {
                              return;
                            }
                            setState(() {
                              selectedAnimalId = value;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: foodController,
                          decoration: const InputDecoration(
                            labelText: 'Food type',
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: quantityController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Quantity (kg)',
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: notesController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Notes (optional)',
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Save'),
                    ),
                  ],
                );
              },
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final String foodType = foodController.text.trim();
    final double? quantity = double.tryParse(quantityController.text.trim());

    if (foodType.isEmpty || quantity == null || quantity <= 0) {
      await _showResultSnack(
        success: false,
        message: 'Food type and a valid quantity are required.',
      );
      return;
    }

    final bool success = await dashboardProvider.logFeeding(
      farmId: farmId,
      animalId: selectedAnimalId,
      foodType: foodType,
      quantity: quantity,
      time: DateTime.now(),
      notes: notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim(),
    );

    await _showResultSnack(
      success: success,
      message: success
          ? (dashboardProvider.actionSuccess ?? 'Feeding log saved.')
          : (dashboardProvider.actionError ?? 'Unable to save feeding log.'),
    );

    if (success) {
      await _refreshAll();
    }
  }

  Future<void> _quickRecordPregnancy() async {
    final SettingsProvider settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final AnimalsProvider animalsProvider = Provider.of<AnimalsProvider>(
      context,
      listen: false,
    );
    final DashboardProvider dashboardProvider = Provider.of<DashboardProvider>(
      context,
      listen: false,
    );

    final String? farmId = settingsProvider.activeFarmId;
    if (farmId == null || farmId.isEmpty) {
      await _showResultSnack(
        success: false,
        message: 'Please select a farm first.',
      );
      return;
    }

    final List<Map<String, String>> animalChoices = _buildAnimalChoices(
      animalsProvider.animals,
    );
    if (animalChoices.isEmpty) {
      await _showResultSnack(
        success: false,
        message: 'Add at least one animal before recording pregnancy.',
      );
      return;
    }

    final TextEditingController notesController = TextEditingController();
    String selectedAnimalId = animalChoices.first['id']!;
    DateTime startDate = DateTime.now();
    DateTime expectedDate = DateTime.now().add(const Duration(days: 150));

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder:
              (BuildContext context, void Function(void Function()) setState) {
                return AlertDialog(
                  title: const Text('Record Pregnancy'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        DropdownButtonFormField<String>(
                          value: selectedAnimalId,
                          decoration: const InputDecoration(
                            labelText: 'Animal',
                          ),
                          items: animalChoices
                              .map(
                                (Map<String, String> item) =>
                                    DropdownMenuItem<String>(
                                      value: item['id'],
                                      child: Text(item['name']!),
                                    ),
                              )
                              .toList(),
                          onChanged: (String? value) {
                            if (value == null) {
                              return;
                            }
                            setState(() {
                              selectedAnimalId = value;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Start date'),
                          subtitle: Text(
                            DateFormat('MMM d, y').format(startDate),
                          ),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: startDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked == null) {
                              return;
                            }
                            setState(() {
                              startDate = picked;
                              if (!expectedDate.isAfter(startDate)) {
                                expectedDate = startDate.add(
                                  const Duration(days: 150),
                                );
                              }
                            });
                          },
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Expected date'),
                          subtitle: Text(
                            DateFormat('MMM d, y').format(expectedDate),
                          ),
                          trailing: const Icon(Icons.event_available),
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: expectedDate,
                              firstDate: startDate.add(const Duration(days: 1)),
                              lastDate: DateTime(2100),
                            );
                            if (picked == null) {
                              return;
                            }
                            setState(() {
                              expectedDate = picked;
                            });
                          },
                        ),
                        TextField(
                          controller: notesController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Notes (optional)',
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Save'),
                    ),
                  ],
                );
              },
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final bool success = await dashboardProvider.recordPregnancy(
      farmId: farmId,
      animalId: selectedAnimalId,
      startDate: startDate,
      expectedDate: expectedDate,
      notes: notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim(),
    );

    await _showResultSnack(
      success: success,
      message: success
          ? (dashboardProvider.actionSuccess ?? 'Pregnancy recorded.')
          : (dashboardProvider.actionError ?? 'Unable to record pregnancy.'),
    );

    if (success) {
      await _refreshAll();
    }
  }

  Future<void> _quickScanTag() async {
    final SettingsProvider settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final AnimalsProvider animalsProvider = Provider.of<AnimalsProvider>(
      context,
      listen: false,
    );
    final DashboardProvider dashboardProvider = Provider.of<DashboardProvider>(
      context,
      listen: false,
    );

    final String? farmId = settingsProvider.activeFarmId;
    if (farmId == null || farmId.isEmpty) {
      await _showResultSnack(
        success: false,
        message: 'Please select a farm first.',
      );
      return;
    }

    final List<Map<String, String>> animalChoices = _buildAnimalChoices(
      animalsProvider.animals,
    );
    if (animalChoices.isEmpty) {
      await _showResultSnack(
        success: false,
        message: 'Add at least one animal before scanning tag.',
      );
      return;
    }

    final TextEditingController tagController = TextEditingController();
    String selectedAnimalId = animalChoices.first['id']!;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder:
              (BuildContext context, void Function(void Function()) setState) {
                return AlertDialog(
                  title: const Text('Scan / Assign Tag'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      DropdownButtonFormField<String>(
                        value: selectedAnimalId,
                        decoration: const InputDecoration(labelText: 'Animal'),
                        items: animalChoices
                            .map(
                              (Map<String, String> item) =>
                                  DropdownMenuItem<String>(
                                    value: item['id'],
                                    child: Text(item['name']!),
                                  ),
                            )
                            .toList(),
                        onChanged: (String? value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            selectedAnimalId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: tagController,
                        decoration: const InputDecoration(
                          labelText: 'Tag code',
                        ),
                      ),
                    ],
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Save'),
                    ),
                  ],
                );
              },
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final String tag = tagController.text.trim();
    if (tag.isEmpty) {
      await _showResultSnack(success: false, message: 'Tag code is required.');
      return;
    }

    final bool success = await dashboardProvider.scanTag(
      farmId: farmId,
      animalId: selectedAnimalId,
      tag: tag,
    );

    await _showResultSnack(
      success: success,
      message: success
          ? (dashboardProvider.actionSuccess ?? 'Tag captured.')
          : (dashboardProvider.actionError ?? 'Unable to capture tag.'),
    );

    if (success) {
      await _refreshAll();
    }
  }

  // ignore: unused_element
  Future<void> _quickRecordActivity() async {
    final SettingsProvider settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final AnimalsProvider animalsProvider = Provider.of<AnimalsProvider>(
      context,
      listen: false,
    );
    final DashboardProvider dashboardProvider = Provider.of<DashboardProvider>(
      context,
      listen: false,
    );

    final String? farmId = settingsProvider.activeFarmId;
    if (farmId == null || farmId.isEmpty) {
      await _showResultSnack(
        success: false,
        message: 'Please select a farm first.',
      );
      return;
    }

    final List<Map<String, String>> animalChoices = _buildAnimalChoices(
      animalsProvider.animals,
    );
    if (animalChoices.isEmpty) {
      await _showResultSnack(
        success: false,
        message: 'Add at least one animal before recording activity.',
      );
      return;
    }

    final TextEditingController activityController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    String selectedAnimalId = animalChoices.first['id']!;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder:
              (BuildContext context, void Function(void Function()) setState) {
                return AlertDialog(
                  title: const Text('Record Activity'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      DropdownButtonFormField<String>(
                        value: selectedAnimalId,
                        decoration: const InputDecoration(labelText: 'Animal'),
                        items: animalChoices
                            .map(
                              (Map<String, String> item) =>
                                  DropdownMenuItem<String>(
                                    value: item['id'],
                                    child: Text(item['name']!),
                                  ),
                            )
                            .toList(),
                        onChanged: (String? value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            selectedAnimalId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: activityController,
                        decoration: const InputDecoration(
                          labelText: 'Activity',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                        ),
                      ),
                    ],
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Save'),
                    ),
                  ],
                );
              },
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final String activity = activityController.text.trim();
    if (activity.isEmpty) {
      await _showResultSnack(success: false, message: 'Activity is required.');
      return;
    }

    final bool success = await dashboardProvider.recordActivity(
      farmId: farmId,
      animalId: selectedAnimalId,
      activity: activity,
      time: DateTime.now(),
      notes: notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim(),
    );

    await _showResultSnack(
      success: success,
      message: success
          ? (dashboardProvider.actionSuccess ?? 'Activity saved.')
          : (dashboardProvider.actionError ?? 'Unable to save activity.'),
    );

    if (success) {
      await _refreshAll();
    }
  }

  Widget _buildFarmSelector({
    required List<Map<String, dynamic>> farms,
    required SettingsProvider settingsProvider,
  }) {
    final String selectedFarmName =
        settingsProvider.activeFarm?['name']?.toString() ?? 'All Farms';
    const Color selectorBg = Color(0xCCB78456);
    final Color selectorText = _textOn(selectorBg);
    final Color selectorMuted = _mutedTextOn(selectorBg);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: selectorBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.pets_outlined, size: 20, color: selectorText),
          const SizedBox(width: 8),
          Text(
            'Farm:',
            style: TextStyle(fontWeight: FontWeight.w700, color: selectorText),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: farms.isEmpty
                ? Text(
                    'No farms available',
                    style: TextStyle(color: selectorMuted),
                  )
                : DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: settingsProvider.activeFarmId,
                      hint: Text(
                        selectedFarmName,
                        style: TextStyle(color: selectorMuted),
                      ),
                      dropdownColor: const Color(0xFFD8B385),
                      iconEnabledColor: selectorText,
                      style: TextStyle(color: selectorText),
                      isExpanded: true,
                      items: farms
                          .map(
                            (Map<String, dynamic> farm) =>
                                DropdownMenuItem<String>(
                                  value: farm['id']?.toString(),
                                  child: Text(
                                    farm['name']?.toString() ?? 'Unnamed Farm',
                                    style: TextStyle(color: selectorText),
                                  ),
                                ),
                          )
                          .toList(),
                      onChanged: (String? value) async {
                        if (widget.onFarmChanged != null) {
                          await widget.onFarmChanged!(value);
                        } else {
                          await settingsProvider.selectActiveFarm(value);
                          if (mounted) {
                            await _refreshAll();
                          }
                        }
                      },
                    ),
                  ),
          ),
          IconButton(
            onPressed: _isRefreshing ? null : _refreshAll,
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.refresh, color: selectorText),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> stats) {
    final List<Map<String, dynamic>> items = <Map<String, dynamic>>[
      <String, dynamic>{
        'title': 'Total Animals',
        'value': stats['totalAnimals'] ?? 0,
        'icon': Icons.pets,
      },
      <String, dynamic>{
        'title': 'Pregnant',
        'value': stats['pregnant'] ?? 0,
        'icon': Icons.egg_alt_outlined,
      },
      <String, dynamic>{
        'title': 'Sick',
        'value': stats['sick'] ?? 0,
        'icon': Icons.cruelty_free,
      },
      <String, dynamic>{
        'title': 'Due Soon',
        'value': stats['upcomingTasks'] ?? 0,
        'icon': Icons.egg_alt,
      },
    ];

    return Row(
      children: List<Widget>.generate(items.length, (int index) {
        final Map<String, dynamic> item = items[index];
        final Color cardColor = _cardColors[index % _cardColors.length];
        final Color accentColor =
            _cardAccentColors[index % _cardAccentColors.length];
        final Color foregroundColor = _textOn(cardColor);

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == items.length - 1 ? 0 : 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: accentColor.withOpacity(0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  item['title'].toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foregroundColor.withOpacity(0.95),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        item['value'].toString(),
                        style: TextStyle(
                          fontSize: 50,
                          fontWeight: FontWeight.w900,
                          color: foregroundColor,
                          height: 1,
                        ),
                      ),
                    ),
                    Icon(
                      item['icon'] as IconData,
                      color: foregroundColor.withOpacity(0.92),
                      size: 30,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildAlerts(RemindersProvider remindersProvider, String? farmId) {
    final List<Map<String, dynamic>> reminders = remindersProvider.reminders;
    const Color alertsBg = Color(0xCCFAC112);
    final Color alertsText = _textOn(alertsBg);
    final Color alertsMuted = _mutedTextOn(alertsBg);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: alertsBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'Upcoming Alerts',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: alertsText,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<Widget>(
                      builder: (_) => const RemindersScreen(),
                    ),
                  );
                },
                child: Text('VIEW ALL', style: TextStyle(color: alertsText)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (remindersProvider.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.3),
                ),
              ),
            )
          else if (reminders.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No reminders scheduled.',
                style: TextStyle(color: alertsMuted),
              ),
            )
          else
            ...reminders.take(4).map((Map<String, dynamic> reminder) {
              final int index = reminders.indexOf(reminder);
              final Color tileColor = _alertColors[index % _alertColors.length];
              final Color tileTextColor = _textOn(tileColor);
              final Color tileMutedColor = _mutedTextOn(tileColor);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: tileColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.notifications_active_outlined,
                      color: tileTextColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            reminder['title']?.toString() ?? 'Reminder',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: tileTextColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatReminderDate(reminder['date']?.toString()),
                            style: TextStyle(
                              fontSize: 12,
                              color: tileMutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Mark done',
                      onPressed: remindersProvider.isLoading
                          ? null
                          : () async {
                              final String reminderId =
                                  reminder['id']?.toString() ?? '';
                              if (reminderId.isEmpty) {
                                return;
                              }
                              final bool success = await remindersProvider
                                  .completeReminder(reminderId, farmId: farmId);
                              await _showResultSnack(
                                success: success,
                                message: success
                                    ? 'Reminder completed.'
                                    : (remindersProvider.error ??
                                          'Failed to complete reminder.'),
                              );
                              if (success) {
                                await _refreshAll();
                              }
                            },
                      icon: Icon(
                        Icons.check_circle_outline,
                        color: tileTextColor,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  List<_ChartPoint> _extractChartPoints(List<dynamic> series, String valueKey) {
    final List<_ChartPoint> points = <_ChartPoint>[];

    for (final dynamic rawItem in series) {
      if (rawItem is! Map) {
        continue;
      }

      final String day = rawItem['day']?.toString() ?? '';
      final String label = day.length >= 10 ? day.substring(8, 10) : '--';
      final dynamic rawValue = rawItem[valueKey];
      final double value = rawValue is num
          ? rawValue.toDouble()
          : (double.tryParse(rawValue?.toString() ?? '') ?? 0);

      points.add(_ChartPoint(label: label, value: value));
    }

    return points;
  }

  Widget _buildActivityGraph(List<dynamic> series, {required bool isLoading}) {
    final List<_ChartPoint> points = _extractChartPoints(series, 'count');
    final double total = points.fold<double>(
      0,
      (double sum, _ChartPoint p) => sum + p.value,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.68),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x22042C71)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Animal Activity',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF0D2E14),
            ),
          ),
          Text(
            'Total activities: ${total.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF5B6A5F)),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 120,
            child: isLoading
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.3),
                    ),
                  )
                : points.isEmpty
                ? const Center(
                    child: Text(
                      'No data available',
                      style: TextStyle(color: Color(0xFF5B6A5F)),
                    ),
                  )
                : _SimpleLineGraph(
                    points: points,
                    lineColor: const Color(0xFF2EAD57),
                  ),
          ),
          if (points.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: points
                  .map(
                    (final _ChartPoint point) => Text(
                      point.label,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF5B6A5F),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMilkGraph(List<dynamic> series, {required bool isLoading}) {
    final List<_ChartPoint> points = _extractChartPoints(series, 'liters');
    final double total = points.fold<double>(
      0,
      (double sum, _ChartPoint p) => sum + p.value,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.68),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x22042C71)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Production',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF0D2E14),
            ),
          ),
          Text(
            'Total liters: ${total.toStringAsFixed(1)}L',
            style: const TextStyle(fontSize: 12, color: Color(0xFF5B6A5F)),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 120,
            child: isLoading
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.3),
                    ),
                  )
                : points.isEmpty
                ? const Center(
                    child: Text(
                      'No data available',
                      style: TextStyle(color: Color(0xFF5B6A5F)),
                    ),
                  )
                : _SimpleBarGraph(
                    points: points,
                    barColor: const Color(0xFF2D7FF9),
                  ),
          ),
          if (points.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: points
                  .map(
                    (final _ChartPoint point) => Text(
                      point.label,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF5B6A5F),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final List<Map<String, dynamic>> actions = <Map<String, dynamic>>[
      <String, dynamic>{
        'label': 'Add Animal',
        'icon': Icons.pets,
        'onTap': _openAddAnimalModal,
      },
      <String, dynamic>{
        'label': 'AI Chat',
        'icon': Icons.smart_toy_outlined,
        'onTap': _openAiChat,
      },
      <String, dynamic>{
        'label': 'Record Treatment',
        'icon': Icons.cruelty_free,
        'onTap': _quickRecordTreatment,
      },
      <String, dynamic>{
        'label': 'Log Feeding',
        'icon': Icons.set_meal_outlined,
        'onTap': _quickLogFeeding,
      },
      <String, dynamic>{
        'label': 'Record Pregnancy',
        'icon': Icons.egg_alt_outlined,
        'onTap': _quickRecordPregnancy,
      },
      <String, dynamic>{
        'label': 'Scan / Tag',
        'icon': Icons.pets_outlined,
        'onTap': _quickScanTag,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.68),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF042C71),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: List<Widget>.generate(actions.length, (int index) {
              final Map<String, dynamic> action = actions[index];
              final Color actionColor =
                  _quickActionColors[index % _quickActionColors.length];

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == actions.length - 1 ? 0 : 6,
                  ),
                  child: Material(
                    color: actionColor,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () async {
                        final Future<void> Function()? handler =
                            action['onTap'] as Future<void> Function()?;
                        if (handler != null) {
                          await handler();
                        }
                      },
                      child: SizedBox(
                        height: 76,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              action['icon'] as IconData,
                              size: 22,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Text(
                                action['label'] as String,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimalSnapshot(
    List<dynamic> snapshot,
    List<dynamic> fallbackAnimals,
  ) {
    final List<dynamic> entries = snapshot.isNotEmpty
        ? snapshot
        : fallbackAnimals;
    const Color snapshotBg = Color(0xCCB78456);
    final Color snapshotText = _textOn(snapshotBg);
    final Color snapshotMuted = _mutedTextOn(snapshotBg);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: snapshotBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Animal Snapshot',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: snapshotText,
            ),
          ),
          const SizedBox(height: 10),
          if (entries.isEmpty)
            Text(
              'No animals available yet.',
              style: TextStyle(color: snapshotMuted),
            )
          else
            ...entries.take(5).map((dynamic raw) {
              if (raw is! Map) {
                return const SizedBox.shrink();
              }

              final String name = raw['name']?.toString() ?? 'Unnamed';
              final String type = raw['type']?.toString() ?? '-';
              final String gender = raw['gender']?.toString() ?? '-';
              final String status =
                  (raw['gestations'] is List &&
                      (raw['gestations'] as List).isNotEmpty)
                  ? 'Pregnancy active'
                  : 'Stable';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: snapshotBg.withOpacity(0.22),
                  border: Border.all(color: snapshotText.withOpacity(0.18)),
                ),
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      backgroundColor: const Color(0xFFDCF2E2),
                      child: Text(
                        name.isEmpty ? '?' : name[0].toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF14311E),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            name,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: snapshotText,
                            ),
                          ),
                          Text(
                            '$type · $gender',
                            style: TextStyle(
                              fontSize: 12,
                              color: snapshotMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: snapshotText,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  String _formatReminderDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'No date';
    }

    try {
      final DateTime parsed = DateTime.parse(value).toLocal();
      return DateFormat('EEE, MMM d • h:mm a').format(parsed);
    } catch (_) {
      return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final DashboardProvider dashboardProvider = Provider.of<DashboardProvider>(
      context,
    );
    final SettingsProvider settingsProvider = Provider.of<SettingsProvider>(
      context,
    );
    final AnimalsProvider animalsProvider = Provider.of<AnimalsProvider>(
      context,
    );
    final RemindersProvider remindersProvider = Provider.of<RemindersProvider>(
      context,
    );

    final Map<String, dynamic> stats =
        dashboardProvider.stats ?? <String, dynamic>{};
    final Map<String, dynamic> trends =
        dashboardProvider.trends ?? <String, dynamic>{};
    final List<dynamic> activitySeries =
        (trends['activity'] as List<dynamic>?) ?? <dynamic>[];
    final List<dynamic> milkSeries =
        (trends['milk'] as List<dynamic>?) ?? <dynamic>[];
    final String? farmId = settingsProvider.activeFarmId;

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/background.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _refreshAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 14,
            bottom: 110,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildSummaryCards(stats),
              const SizedBox(height: 14),
              _buildAlerts(remindersProvider, farmId),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _buildActivityGraph(
                      activitySeries,
                      isLoading: dashboardProvider.isLoading,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMilkGraph(
                      milkSeries,
                      isLoading: dashboardProvider.isLoading,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildQuickActions(),
              const SizedBox(height: 14),
              _buildAnimalSnapshot(
                dashboardProvider.animalSnapshot ?? <dynamic>[],
                animalsProvider.animals,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartPoint {
  final String label;
  final double value;

  const _ChartPoint({required this.label, required this.value});
}

class _SimpleLineGraph extends StatelessWidget {
  final List<_ChartPoint> points;
  final Color lineColor;

  const _SimpleLineGraph({required this.points, required this.lineColor});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LineGraphPainter(points: points, lineColor: lineColor),
      child: const SizedBox.expand(),
    );
  }
}

class _SimpleBarGraph extends StatelessWidget {
  final List<_ChartPoint> points;
  final Color barColor;

  const _SimpleBarGraph({required this.points, required this.barColor});

  @override
  Widget build(BuildContext context) {
    final double max = points
        .map((final _ChartPoint p) => p.value)
        .fold<double>(0, (final double a, final double b) => a > b ? a : b);
    final double maxValue = max <= 0 ? 1 : max;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: points
          .map(
            (final _ChartPoint point) => Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: (point.value / maxValue) * 105,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _LineGraphPainter extends CustomPainter {
  final List<_ChartPoint> points;
  final Color lineColor;

  const _LineGraphPainter({required this.points, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint axisPaint = Paint()
      ..color = const Color(0xFF434F75)
      ..strokeWidth = 1;
    final Paint linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final Paint fillPaint = Paint()
      ..color = lineColor.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    final Paint dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      axisPaint,
    );

    final double max = points
        .map((final _ChartPoint p) => p.value)
        .fold<double>(0, (final double a, final double b) => a > b ? a : b);
    final double maxValue = max <= 0 ? 1 : max;

    final Path linePath = Path();
    final Path fillPath = Path();
    for (int i = 0; i < points.length; i++) {
      final double x = points.length == 1
          ? size.width / 2
          : (i / (points.length - 1)) * size.width;
      final double y =
          size.height - ((points[i].value / maxValue) * (size.height - 8));

      if (i == 0) {
        linePath.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      canvas.drawCircle(Offset(x, y), 3.5, dotPaint);
    }

    if (points.isNotEmpty) {
      final double endX = points.length == 1 ? size.width / 2 : size.width;
      fillPath.lineTo(endX, size.height);
      fillPath.close();
      canvas.drawPath(fillPath, fillPaint);
      canvas.drawPath(linePath, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineGraphPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.lineColor != lineColor;
  }
}
