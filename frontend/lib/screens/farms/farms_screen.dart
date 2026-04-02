import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';

class FarmsScreen extends StatefulWidget {
  const FarmsScreen({super.key});

  @override
  State<FarmsScreen> createState() => _FarmsScreenState();
}

class _FarmsScreenState extends State<FarmsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SettingsProvider>(context, listen: false).fetchFarmLocations();
    });
  }

  Future<void> _showCreateFarmDialog() async {
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final sizeController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final payload = await showDialog<_CreateFarmPayload>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Farm'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Farm Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Farm name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: sizeController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Size in acres (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                final size = double.tryParse(sizeController.text.trim());
                Navigator.pop(
                  dialogContext,
                  _CreateFarmPayload(
                    name: nameController.text,
                    location: locationController.text,
                    size: size,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    locationController.dispose();
    sizeController.dispose();

    if (!mounted || payload == null) {
      return;
    }

    final provider = Provider.of<SettingsProvider>(context, listen: false);
    final ok = await provider.createFarm(
      name: payload.name,
      location: payload.location,
      size: payload.size,
    );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Farm created successfully.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Failed to create farm')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farms'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, _) {
          final farms = (settingsProvider.farmLocations ?? [])
              .whereType<Map>()
              .map((farm) => Map<String, dynamic>.from(farm))
              .toList();

          if (settingsProvider.isLoading && farms.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: settingsProvider.fetchFarmLocations,
            child: farms.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 120),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.agriculture_outlined, size: 56, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            const Text('No farms yet'),
                            const SizedBox(height: 8),
                            const Text('Add your first farm to start farm-specific tracking.'),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _showCreateFarmDialog,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Farm'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    itemCount: farms.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final farm = farms[index];
                      final farmId = farm['id']?.toString() ?? '';
                      final isActive = settingsProvider.activeFarmId == farmId;

                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          await settingsProvider.selectActiveFarm(farmId);
                          if (!mounted) return;
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(content: Text('Active farm set to ${farm['name'] ?? 'Farm'}')),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isActive ? const Color(0xFF13EC5B) : const Color(0xFFE6E6E6),
                              width: isActive ? 1.8 : 1,
                            ),
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              const Icon(Icons.agriculture_outlined),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      farm['name']?.toString() ?? 'Unnamed Farm',
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      farm['location']?.toString().isNotEmpty == true
                                          ? farm['location'].toString()
                                          : 'No location set',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              if (isActive)
                                const Icon(Icons.check_circle, color: Color(0xFF13EC5B))
                              else
                                const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateFarmDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Farm'),
      ),
    );
  }
}

class _CreateFarmPayload {
  final String name;
  final String location;
  final double? size;

  const _CreateFarmPayload({
    required this.name,
    required this.location,
    required this.size,
  });
}
