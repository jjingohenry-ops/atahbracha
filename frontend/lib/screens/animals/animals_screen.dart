import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_base.dart';
import '../../core/services/insurance_service.dart';
import '../../core/services/prescription_service.dart';
import '../../providers/animals_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';

class AnimalsScreen extends StatefulWidget {
  const AnimalsScreen({super.key});

  @override
  State<AnimalsScreen> createState() => _AnimalsScreenState();
}

class _AnimalsScreenState extends State<AnimalsScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      Provider.of<AnimalsProvider>(context, listen: false)
          .fetchAnimals(farmId: settingsProvider.activeFarmId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/bg1.jpg'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                theme.brightness == Brightness.dark
                    ? Colors.black.withOpacity(0.45)
                    : Colors.white.withOpacity(0.12),
                theme.brightness == Brightness.dark ? BlendMode.darken : BlendMode.lighten,
              ),
            ),
          ),
          child: Container(
            color: theme.brightness == Brightness.dark
                ? colorScheme.surface.withOpacity(0.68)
                : Colors.white.withOpacity(0.42),
            child: Column(
              children: [
                _buildSearch(theme, colorScheme),
                Expanded(child: _buildAnimalTypeList(theme, colorScheme)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearch(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value.trim().toLowerCase()),
        style: TextStyle(color: colorScheme.onSurface),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search, color: colorScheme.onSurface.withOpacity(0.7)),
          hintText: 'Search animal type...',
          hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.65)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: colorScheme.surface.withOpacity(theme.brightness == Brightness.dark ? 0.85 : 1),
        ),
      ),
    );
  }

  Widget _buildAnimalTypeList(ThemeData theme, ColorScheme colorScheme) {
    return Consumer<AnimalsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return _buildErrorState(provider.error!);
        }

        final allAnimals = provider.animals.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        final Map<String, int> countsByType = <String, int>{};

        for (final animal in allAnimals) {
          final type = _normalizeType(animal['type']?.toString() ?? 'OTHER');
          countsByType[type] = (countsByType[type] ?? 0) + 1;
        }

        final rows = countsByType.entries.toList()
          ..sort((a, b) {
            final int byCount = b.value.compareTo(a.value);
            if (byCount != 0) return byCount;
            return _formatType(a.key).compareTo(_formatType(b.key));
          });

        final filteredRows = rows.where((entry) {
          if (_searchQuery.isEmpty) return true;
          final label = _formatType(entry.key).toLowerCase();
          return label.contains(_searchQuery);
        }).toList();

        if (filteredRows.isEmpty) {
          return Center(
            child: Text(
              'No animal types found',
              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.72), fontWeight: FontWeight.w600),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          itemCount: filteredRows.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final entry = filteredRows[index];
            final type = entry.key;
            final count = entry.value;

            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AnimalTypeAnimalsScreen(type: type),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withOpacity(theme.brightness == Brightness.dark ? 0.88 : 1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Text(_animalEmoji(type), style: const TextStyle(fontSize: 26)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _formatType(type),
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$count',
                          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                        ),
                        Text(
                          count == 1 ? 'Animal' : 'Animals',
                          style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withOpacity(0.7)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red[300]!),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 12),
              Text(
                'Unable to Load Animals',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red[700]),
              ),
              const SizedBox(height: 8),
              Text(
                error.isNotEmpty ? error : 'Please try again in a moment.',
                style: TextStyle(fontSize: 13, color: Colors.red[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
                  Provider.of<AnimalsProvider>(context, listen: false)
                      .fetchAnimals(farmId: settingsProvider.activeFarmId);
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimalTypeAnimalsScreen extends StatefulWidget {
  final String type;

  const AnimalTypeAnimalsScreen({super.key, required this.type});

  @override
  State<AnimalTypeAnimalsScreen> createState() => _AnimalTypeAnimalsScreenState();
}

class _AnimalTypeAnimalsScreenState extends State<AnimalTypeAnimalsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text('${_formatType(widget.type)} Animals'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value.trim().toLowerCase()),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: colorScheme.onSurface.withOpacity(0.7)),
                hintText: 'Search by name or tag...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withOpacity(theme.brightness == Brightness.dark ? 0.6 : 1),
              ),
            ),
          ),
          Expanded(
            child: Consumer<AnimalsProvider>(
              builder: (context, provider, _) {
                final animals = provider.animals
                    .whereType<Map>()
                    .map((e) => Map<String, dynamic>.from(e))
                    .where((animal) => _normalizeType(animal['type']?.toString() ?? 'OTHER') == _normalizeType(widget.type))
                    .where((animal) {
                      if (_searchQuery.isEmpty) return true;
                      final name = (animal['name'] ?? '').toString().toLowerCase();
                      final tag = (animal['tagNumber'] ?? animal['id'] ?? '').toString().toLowerCase();
                      return name.contains(_searchQuery) || tag.contains(_searchQuery);
                    })
                    .toList();

                if (animals.isEmpty) {
                  return Center(
                    child: Text(
                      'No ${_formatType(widget.type).toLowerCase()} animals found',
                      style: TextStyle(color: colorScheme.onSurface.withOpacity(0.72), fontWeight: FontWeight.w600),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemCount: animals.length,
                  itemBuilder: (context, index) {
                    final animal = animals[index];
                    final status = _statusLabel(animal['status']?.toString());
                    final statusColor = _statusColor(status);

                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AnimalProfileScreen(animalId: animal['id']?.toString() ?? '', initialAnimal: animal),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: const Color(0xFF13EC5B).withOpacity(0.14),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(_animalEmoji(widget.type), style: const TextStyle(fontSize: 28)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (animal['name'] ?? 'Unnamed').toString(),
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: colorScheme.onSurface),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tag: ${(animal['tagNumber'] ?? animal['id'] ?? 'N/A').toString()}',
                                    style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AnimalProfileScreen extends StatefulWidget {
  final String animalId;
  final Map<String, dynamic> initialAnimal;

  const AnimalProfileScreen({
    super.key,
    required this.animalId,
    required this.initialAnimal,
  });

  @override
  State<AnimalProfileScreen> createState() => _AnimalProfileScreenState();
}

class _AnimalProfileScreenState extends State<AnimalProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final InsuranceService _insuranceService = InsuranceService();
  final PrescriptionService _prescriptionService = PrescriptionService();

  late Map<String, dynamic> _animal;
  late TextEditingController _notesController;
  late TextEditingController _pedigreeController;

  final Map<String, bool> _dailyChecklist = <String, bool>{
    'Morning feeding': false,
    'Clean water': true,
    'Health observation': false,
    'Evening feeding': false,
  };

  List<String> _galleryUrls = <String>[];
  List<InsuranceProviderEntry> _insuranceProviders = <InsuranceProviderEntry>[];
  Set<String> _savedProviderIds = <String>{};
  List<PrescriptionEntry> _prescriptions = <PrescriptionEntry>[];
  bool _prescriptionsLoading = false;
  String? _prescriptionsError;
  bool _insuranceLoading = false;
  String? _insuranceError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _animal = Map<String, dynamic>.from(widget.initialAnimal);
    _notesController = TextEditingController(text: (_animal['notes'] ?? '').toString());
    _pedigreeController = TextEditingController(text: (_animal['pedigree'] ?? '').toString());

    final heroPhoto = _resolvePhotoUrl(_animal['photoUrl']?.toString());
    if (heroPhoto != null) {
      _galleryUrls = <String>[heroPhoto];
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInsuranceProviders();
      _loadPrescriptions();
      _prescriptionService.syncPendingOperations();
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _pedigreeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Animal Profile'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: Consumer<AnimalsProvider>(
        builder: (context, provider, _) {
          final fromProvider = _findAnimalById(provider.animals, widget.animalId);
          if (fromProvider != null) {
            _animal = fromProvider;
          }

          final type = _normalizeType(_animal['type']?.toString() ?? 'OTHER');
          final status = _statusLabel(_animal['status']?.toString());
          final statusColor = _statusColor(status);
          final heroPhoto = _resolvePhotoUrl(_animal['photoUrl']?.toString());

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderCard(type: type, status: status, statusColor: statusColor, heroPhoto: heroPhoto),
                const SizedBox(height: 12),
                _buildQuickStats(),
                const SizedBox(height: 12),
                _buildHealthSection(),
                const SizedBox(height: 12),
                _buildInsuranceSection(),
                const SizedBox(height: 12),
                _buildGestationSection(),
                const SizedBox(height: 12),
                _buildFeedingSection(),
                const SizedBox(height: 12),
                _buildPrescriptionSection(),
                const SizedBox(height: 12),
                _buildTrendSection(),
                const SizedBox(height: 12),
                _buildNotesAndPedigreeSection(),
                const SizedBox(height: 12),
                _buildMediaGallery(heroPhoto),
                const SizedBox(height: 12),
                _buildQuickActions(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard({
    required String type,
    required String status,
    required Color statusColor,
    required String? heroPhoto,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: SizedBox(
              height: 220,
              width: double.infinity,
              child: heroPhoto != null
                  ? Image.network(
                      heroPhoto,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallbackHero(type),
                    )
                  : _fallbackHero(type),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (_animal['name'] ?? 'Unnamed animal').toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tag: ${(_animal['tagNumber'] ?? _animal['id'] ?? 'N/A').toString()}',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: statusColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackHero(String type) {
    return Container(
      color: const Color(0xFFEBF8EE),
      alignment: Alignment.center,
      child: Text(_animalEmoji(type), style: const TextStyle(fontSize: 90)),
    );
  }

  Widget _buildQuickStats() {
    final colorScheme = Theme.of(context).colorScheme;
    final stats = <Map<String, dynamic>>[
      {
        'label': 'Weight',
        'value': _animal['weight'] != null ? '${_animal['weight']} kg' : 'Not set',
        'icon': Icons.monitor_weight_outlined,
      },
      {
        'label': 'Age',
        'value': _animal['age'] != null ? '${_animal['age']} yrs' : 'Not set',
        'icon': Icons.cake_outlined,
      },
      {
        'label': 'Breed',
        'value': (_animal['breed'] ?? 'Unknown').toString(),
        'icon': Icons.account_tree_outlined,
      },
      {
        'label': 'Last Checkup',
        'value': _humanDate(_animal['lastCheckupAt'] ?? _animal['updatedAt']),
        'icon': Icons.health_and_safety_outlined,
      },
    ];

    return SizedBox(
      height: 122,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final stat = stats[index];
          return Container(
            width: 152,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(stat['icon'] as IconData, size: 18, color: const Color(0xFF234B8D)),
                const SizedBox(height: 10),
                Text(
                  stat['label'] as String,
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.7)),
                ),
                const SizedBox(height: 4),
                Text(
                  stat['value'] as String,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHealthSection() {
    final vaccines = (_animal['vaccinations'] as List?)?.length ?? 0;
    final treatments = (_animal['treatments'] as List?)?.length ?? 0;
    final alerts = (_animal['alerts'] as List?)?.length ?? 0;

    return _sectionCard(
      title: 'Health',
      icon: Icons.favorite_outline,
      child: Column(
        children: [
          _metricTile(Icons.vaccines_outlined, 'Vaccinations', '$vaccines records'),
          const SizedBox(height: 8),
          _metricTile(Icons.healing_outlined, 'Treatments', '$treatments records'),
          const SizedBox(height: 8),
          _metricTile(Icons.warning_amber_outlined, 'Alerts', '$alerts active alerts'),
        ],
      ),
    );
  }

  Widget _buildGestationSection() {
    final progress = _gestationProgress(_animal);
    final dueDate = _humanDate(_animal['expectedDeliveryDate']);
    final serviceDate = _humanDate(_animal['serviceDate']);

    return _sectionCard(
      title: 'Breeding & Gestation',
      icon: Icons.timeline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Progress', style: TextStyle(fontWeight: FontWeight.w600)),
              Text('${(progress * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            minHeight: 10,
            value: progress,
            borderRadius: BorderRadius.circular(20),
            backgroundColor: const Color(0xFFEDEDED),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF13EC5B)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _dateChip('Service date', serviceDate)),
              const SizedBox(width: 8),
              Expanded(child: _dateChip('Expected date', dueDate)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsuranceSection() {
    return _sectionCard(
      title: 'Insurance',
      icon: Icons.shield_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_insuranceLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_insuranceProviders.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _insuranceError ?? 'No providers available for this animal type and region yet.',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
            )
          else
            Column(
              children: _insuranceProviders.map((provider) {
                final saved = _savedProviderIds.contains(provider.id);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE7E7E7)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              provider.name,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                          ),
                          if (saved)
                            const Icon(Icons.bookmark, size: 16, color: Color(0xFF2B5FB8)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        provider.coverageSummary,
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: provider.supportedAnimalTypes
                            .map(
                              (type) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE0E0E0)),
                                ),
                                child: Text(
                                  _formatType(type),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: () => _showInsuranceContactOptions(provider),
                            icon: const Icon(Icons.contact_phone_outlined, size: 16),
                            label: const Text('Contact'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => _toggleProviderSaved(provider.id),
                            icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border, size: 16),
                            label: Text(saved ? 'Saved' : 'Save for later'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildFeedingSection() {
    return _sectionCard(
      title: 'Feeding & Daily Care',
      icon: Icons.restaurant_outlined,
      child: Column(
        children: _dailyChecklist.entries.map((entry) {
          return CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            value: entry.value,
            title: Text(entry.key, style: const TextStyle(fontSize: 14)),
            activeColor: const Color(0xFF13EC5B),
            onChanged: (checked) {
              setState(() {
                _dailyChecklist[entry.key] = checked ?? false;
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPrescriptionSection() {
    return _sectionCard(
      title: 'Prescriptions & Treatment Tracker',
      icon: Icons.medical_services_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Log doses quickly, even with unstable network.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              FilledButton.icon(
                onPressed: _openCreatePrescriptionDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_prescriptionsLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_prescriptions.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _prescriptionsError ?? 'No prescriptions yet. Tap New to add one.',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
            )
          else
            Column(
              children: _prescriptions.map((prescription) {
                final progress = prescription.progress.clamp(0.0, 1.0);
                final statusColor = _prescriptionStatusColor(prescription);

                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _openPrescriptionDetails(prescription),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE7E7E7)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                prescription.diagnosis,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.16),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${(progress * 100).round()}%',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          (prescription.vetName ?? '').isEmpty
                              ? 'Vet: Not recorded'
                              : 'Vet: ${prescription.vetName}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(20),
                          backgroundColor: const Color(0xFFECECEC),
                          valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        ),
                        const SizedBox(height: 8),
                        ...prescription.items.take(2).map((item) {
                          final canMark = item.remainingDoses > 0;
                          final itemStatusColor = _doseStatusColor(item.statusColor);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFEAEAEA)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.drugName,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                      ),
                                      Text(
                                        '${item.dosage} • ${item.completedDoses}/${item.totalDoses} doses',
                                        style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: itemStatusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                FilledButton.tonal(
                                  onPressed: canMark
                                      ? () => _markDoseAsGiven(
                                            prescriptionId: prescription.id,
                                            itemId: item.id,
                                          )
                                      : null,
                                  child: Text(canMark ? 'Mark given' : 'Done'),
                                ),
                              ],
                            ),
                          );
                        }),
                        if (prescription.items.length > 2)
                          Text(
                            '+${prescription.items.length - 2} more drug(s)',
                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Future<void> _loadPrescriptions() async {
    if (widget.animalId.isEmpty) return;

    setState(() {
      _prescriptionsLoading = true;
      _prescriptionsError = null;
    });

    try {
      final list = await _prescriptionService.fetchByAnimal(widget.animalId);
      if (!mounted) return;

      setState(() {
        _prescriptions = list;
        _prescriptionsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _prescriptionsLoading = false;
        _prescriptionsError = 'Unable to load prescriptions now.';
      });
    }
  }

  Future<void> _markDoseAsGiven({required String prescriptionId, required String itemId}) async {
    final success = await _prescriptionService.markDoseGiven(
      animalId: widget.animalId,
      prescriptionId: prescriptionId,
      itemId: itemId,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Dose logged. It will sync automatically if offline.'
              : 'Could not log dose right now.',
        ),
      ),
    );

    await _loadPrescriptions();
  }

  void _openPrescriptionDetails(PrescriptionEntry prescription) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prescription.diagnosis,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (prescription.vetName ?? '').isEmpty
                        ? 'Vet: Not specified'
                        : 'Vet: ${prescription.vetName}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  if (prescription.notes != null && prescription.notes!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      prescription.notes!,
                      style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                    ),
                  ],
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: prescription.progress.clamp(0.0, 1.0),
                    minHeight: 9,
                    borderRadius: BorderRadius.circular(20),
                    backgroundColor: const Color(0xFFECECEC),
                    valueColor: AlwaysStoppedAnimation<Color>(_prescriptionStatusColor(prescription)),
                  ),
                  const SizedBox(height: 14),
                  ...prescription.items.map((item) {
                    final canMark = item.remainingDoses > 0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E5E5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.drugName,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _doseStatusColor(item.statusColor).withOpacity(0.16),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  item.statusColor,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _doseStatusColor(item.statusColor),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${item.dosage} • ${item.frequencyPerDay}x/day • ${item.durationDays} day(s)',
                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                          ),
                          Text(
                            'Progress: ${item.completedDoses}/${item.totalDoses} doses',
                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                          ),
                          if (item.withdrawalPeriodDays != null)
                            Text(
                              'Withdrawal: ${item.withdrawalPeriodDays} day(s)',
                              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                            ),
                          const SizedBox(height: 8),
                          FilledButton.tonalIcon(
                            onPressed: canMark
                                ? () {
                                    Navigator.pop(context);
                                    _markDoseAsGiven(
                                      prescriptionId: prescription.id,
                                      itemId: item.id,
                                    );
                                  }
                                : null,
                            icon: const Icon(Icons.check, size: 16),
                            label: Text(canMark ? 'Mark as given' : 'Completed'),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openCreatePrescriptionDialog() async {
    final diagnosisController = TextEditingController();
    final vetController = TextEditingController();
    final notesController = TextEditingController();

    final List<Map<String, dynamic>> draftItems = <Map<String, dynamic>>[
      {
        'drugName': 'Oxytetracycline',
        'dosage': '10 ml',
        'frequencyPerDay': 1,
        'durationDays': 3,
        'withdrawalPeriodDays': 7,
      },
    ];

    const commonDrugs = <String>[
      'Oxytetracycline',
      'Penicillin',
      'Albendazole',
      'Ivermectin',
      'Vitamin B Complex',
      'Other',
    ];

    final bool? submitted = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('New Prescription'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: diagnosisController,
                      decoration: const InputDecoration(labelText: 'Diagnosis'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: vetController,
                      decoration: const InputDecoration(labelText: 'Vet name (optional)'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      minLines: 2,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Notes (optional)'),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Drugs',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey[800]),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(draftItems.length, (index) {
                      final item = draftItems[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F9FA),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              value: commonDrugs.contains(item['drugName']) ? item['drugName'] as String : 'Other',
                              items: commonDrugs
                                  .map((drug) => DropdownMenuItem(value: drug, child: Text(drug)))
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                setLocalState(() {
                                  item['drugName'] = value == 'Other' ? '' : value;
                                });
                              },
                              decoration: const InputDecoration(labelText: 'Drug'),
                            ),
                            if ((item['drugName'] ?? '').toString().isEmpty)
                              TextField(
                                onChanged: (value) => item['drugName'] = value,
                                decoration: const InputDecoration(labelText: 'Custom drug name'),
                              ),
                            TextField(
                              controller: TextEditingController(text: (item['dosage'] ?? '').toString()),
                              onChanged: (value) => item['dosage'] = value,
                              decoration: const InputDecoration(labelText: 'Dosage'),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: TextEditingController(
                                      text: (item['frequencyPerDay'] ?? 1).toString(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) => item['frequencyPerDay'] = int.tryParse(value) ?? 1,
                                    decoration: const InputDecoration(labelText: 'Freq/day'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: TextEditingController(
                                      text: (item['durationDays'] ?? 1).toString(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) => item['durationDays'] = int.tryParse(value) ?? 1,
                                    decoration: const InputDecoration(labelText: 'Duration days'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          setLocalState(() {
                            draftItems.add({
                              'drugName': 'Oxytetracycline',
                              'dosage': '10 ml',
                              'frequencyPerDay': 1,
                              'durationDays': 3,
                              'withdrawalPeriodDays': 7,
                            });
                          });
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add drug'),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (submitted != true) {
      diagnosisController.dispose();
      vetController.dispose();
      notesController.dispose();
      return;
    }

    final diagnosis = diagnosisController.text.trim();
    final vetNameValue = vetController.text.trim();
    final notesValue = notesController.text.trim();
    final items = draftItems
        .where((item) => (item['drugName'] ?? '').toString().trim().isNotEmpty)
        .map((item) => {
              'drugName': (item['drugName'] ?? '').toString().trim(),
              'dosage': (item['dosage'] ?? '').toString().trim(),
              'frequencyPerDay': item['frequencyPerDay'] ?? 1,
              'durationDays': item['durationDays'] ?? 1,
              'withdrawalPeriodDays': item['withdrawalPeriodDays'] ?? 0,
              'startDate': DateTime.now().toIso8601String(),
            })
        .where((item) => (item['dosage'] ?? '').toString().isNotEmpty)
        .toList();

    diagnosisController.dispose();
    vetController.dispose();
    notesController.dispose();

    if (diagnosis.isEmpty || items.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diagnosis and at least one valid drug item are required.')),
      );
      return;
    }

    final success = await _prescriptionService.createPrescription(
      animalId: widget.animalId,
      diagnosis: diagnosis,
      vetName: vetNameValue.isEmpty ? null : vetNameValue,
      notes: notesValue.isEmpty ? null : notesValue,
      items: items,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Prescription saved. Offline entries sync automatically.'
              : 'Unable to save prescription right now.',
        ),
      ),
    );

    await _loadPrescriptions();
  }

  Color _prescriptionStatusColor(PrescriptionEntry prescription) {
    if (prescription.items.isEmpty) return const Color(0xFF889096);

    final hasRed = prescription.items.any((item) => item.statusColor.toUpperCase() == 'RED');
    if (hasRed) return const Color(0xFFD64545);

    final hasYellow = prescription.items.any((item) => item.statusColor.toUpperCase() == 'YELLOW');
    if (hasYellow) return const Color(0xFFE8A317);

    return const Color(0xFF2E9A57);
  }

  Color _doseStatusColor(String statusColor) {
    final code = statusColor.toUpperCase();
    if (code == 'RED') return const Color(0xFFD64545);
    if (code == 'YELLOW') return const Color(0xFFE8A317);
    return const Color(0xFF2E9A57);
  }

  Widget _buildTrendSection() {
    final weight = (_animal['weight'] as num?)?.toDouble() ?? 100;
    final values = <double>[
      math.max(30, weight * 0.78),
      math.max(30, weight * 0.84),
      math.max(30, weight * 0.89),
      math.max(30, weight * 0.94),
      math.max(30, weight),
    ];

    final maxV = values.reduce(math.max);

    return _sectionCard(
      title: 'Performance Trends',
      icon: Icons.show_chart,
      child: SizedBox(
        height: 120,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: values.map((value) {
            final height = (value / maxV) * 96;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B5FB8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNotesAndPedigreeSection() {
    return _sectionCard(
      title: 'Notes & Pedigree',
      icon: Icons.edit_note_outlined,
      child: Column(
        children: [
          TextField(
            controller: _notesController,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Notes',
              suffixIcon: IconButton(
                icon: const Icon(Icons.mic_none),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Voice input will be enabled in a follow-up step.')),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _pedigreeController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Pedigree',
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _saveNotes,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined, size: 18),
              label: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaGallery(String? heroPhoto) {
    final urls = <String>{..._galleryUrls};
    if (heroPhoto != null) {
      urls.add(heroPhoto);
    }

    final media = urls.toList();

    return _sectionCard(
      title: 'Media Gallery',
      icon: Icons.photo_library_outlined,
      child: SizedBox(
        height: 94,
        child: Row(
          children: [
            InkWell(
              onTap: _addMedia,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7EE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFE9CC)),
                ),
                child: const Icon(Icons.add_a_photo_outlined, color: Color(0xFF2A7A47)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: media.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final url = media[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      url,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 90,
                        height: 90,
                        color: Colors.grey[200],
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            onPressed: _openCreatePrescriptionDialog,
            icon: const Icon(Icons.medical_services_outlined, size: 18),
            label: const Text('Add treatment'),
          ),
          OutlinedButton.icon(
            onPressed: _updateWeight,
            icon: const Icon(Icons.monitor_weight_outlined, size: 18),
            label: const Text('Update weight'),
          ),
          OutlinedButton.icon(
            onPressed: _addMedia,
            icon: const Icon(Icons.upload_file_outlined, size: 18),
            label: const Text('Upload media'),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required IconData icon, required Widget child}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF234B8D), size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _metricTile(IconData icon, String title, String subtitle) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.55),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2B5FB8), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }

  double _gestationProgress(Map<String, dynamic> animal) {
    final rawProgress = animal['gestationProgress'];
    if (rawProgress is num) {
      final p = rawProgress.toDouble();
      if (p > 1) return (p / 100).clamp(0.0, 1.0);
      return p.clamp(0.0, 1.0);
    }

    final start = _parseDate(animal['serviceDate']);
    final end = _parseDate(animal['expectedDeliveryDate']);
    if (start == null || end == null) return 0.35;

    final total = end.difference(start).inDays;
    if (total <= 0) return 0.0;

    final elapsed = DateTime.now().difference(start).inDays;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  String _humanDate(dynamic value) {
    final date = _parseDate(value);
    if (date == null) return 'Not set';
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Map<String, dynamic>? _findAnimalById(List<dynamic> list, String animalId) {
    for (final item in list) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      if ((map['id'] ?? '').toString() == animalId) {
        return map;
      }
    }
    return null;
  }

  Future<void> _saveNotes() async {
    if (widget.animalId.isEmpty) return;

    setState(() => _saving = true);

    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final provider = Provider.of<AnimalsProvider>(context, listen: false);

    final success = await provider.updateAnimal(
      widget.animalId,
      {
        'notes': _notesController.text.trim(),
        'pedigree': _pedigreeController.text.trim(),
      },
      farmId: settings.activeFarmId,
    );

    if (!mounted) return;

    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Saved' : (provider.error ?? 'Unable to save'))),
    );
  }

  Future<void> _updateWeight() async {
    final controller = TextEditingController(text: (_animal['weight'] ?? '').toString());

    final result = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Weight'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Weight (kg)'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, double.tryParse(controller.text.trim()));
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (result == null || widget.animalId.isEmpty) return;

    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final provider = Provider.of<AnimalsProvider>(context, listen: false);

    final success = await provider.updateAnimal(
      widget.animalId,
      {'weight': result},
      farmId: settings.activeFarmId,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Weight updated' : (provider.error ?? 'Unable to update weight'))),
    );
  }

  Future<void> _addMedia() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (picked == null) return;

    final provider = Provider.of<AnimalsProvider>(context, listen: false);
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    final uploadedUrl = await provider.uploadAnimalPhoto(picked);

    if (!mounted) return;

    if (uploadedUrl == null || uploadedUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Failed to upload media')),
      );
      return;
    }

    setState(() {
      _galleryUrls = <String>{..._galleryUrls, uploadedUrl}.toList();
    });

    if (widget.animalId.isNotEmpty) {
      await provider.updateAnimal(
        widget.animalId,
        {'photoUrl': uploadedUrl},
        farmId: settings.activeFarmId,
      );
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Media uploaded')),
    );
  }

  Future<void> _loadInsuranceProviders() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final country = _countryFromSettings(settings);
    final animalType = _normalizeType(_animal['type']?.toString() ?? 'OTHER');

    setState(() {
      _insuranceLoading = true;
      _insuranceError = null;
    });

    try {
      await _insuranceService.preloadProviders(
        country: country,
        animalTypes: <String>[animalType],
      );

      final providers = await _insuranceService.fetchProviders(
        country: country,
        animalType: animalType,
      );
      final savedIds = await _insuranceService.getSavedProviderIds();

      if (!mounted) return;

      setState(() {
        _insuranceProviders = providers;
        _savedProviderIds = savedIds;
        _insuranceLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _insuranceLoading = false;
        _insuranceError = 'Unable to load insurance providers right now.';
      });
    }
  }

  String _countryFromSettings(SettingsProvider settings) {
    final raw = settings.activeFarm?['location']?.toString().trim();
    if (raw == null || raw.isEmpty) return 'UG';

    final upper = raw.toUpperCase();
    if (upper.contains('UGANDA')) return 'UG';
    if (upper.contains('KENYA')) return 'KE';
    if (upper.contains('TANZANIA')) return 'TZ';
    if (upper.contains('RWANDA')) return 'RW';
    if (upper.contains('BURUNDI')) return 'BI';

    // If the location starts with a 2-letter country code, keep it.
    if (upper.length >= 2 && RegExp(r'^[A-Z]{2}').hasMatch(upper)) {
      return upper.substring(0, 2);
    }

    return 'UG';
  }

  Future<void> _toggleProviderSaved(String providerId) async {
    await _insuranceService.toggleSavedProvider(providerId);
    final updated = await _insuranceService.getSavedProviderIds();
    if (!mounted) return;
    setState(() => _savedProviderIds = updated);
  }

  void _showInsuranceContactOptions(InsuranceProviderEntry provider) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(provider.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 10),
              if (provider.phone != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.call_outlined),
                  title: Text(provider.phone!),
                  subtitle: const Text('Call provider'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text('Call ${provider.phone}')),
                    );
                  },
                ),
              if (provider.whatsapp != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.chat_bubble_outline),
                  title: Text(provider.whatsapp!),
                  subtitle: const Text('WhatsApp provider'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text('WhatsApp ${provider.whatsapp}')),
                    );
                  },
                ),
              if (provider.email != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.email_outlined),
                  title: Text(provider.email!),
                  subtitle: const Text('Email provider'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text('Email ${provider.email}')),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

String _normalizeType(String type) {
  final normalized = type.trim().toUpperCase();
  if (normalized == 'COW') return 'CATTLE';
  if (normalized.isEmpty) return 'OTHER';
  return normalized;
}

String _formatType(String type) {
  final normalized = _normalizeType(type);
  switch (normalized) {
    case 'CATTLE':
      return 'Cattle';
    case 'GOAT':
      return 'Goat';
    case 'SHEEP':
      return 'Sheep';
    case 'PIG':
      return 'Pig';
    case 'CHICKEN':
      return 'Chicken';
    case 'HORSE':
      return 'Horse';
    case 'DOG':
      return 'Dog';
    case 'CAT':
      return 'Cat';
    case 'RABBIT':
      return 'Rabbit';
    case 'MICE':
      return 'Mice';
    case 'FISH':
      return 'Fish';
    default:
      return normalized[0] + normalized.substring(1).toLowerCase();
  }
}

String _animalEmoji(String type) {
  switch (_normalizeType(type)) {
    case 'CATTLE':
      return '🐄';
    case 'GOAT':
      return '🐐';
    case 'SHEEP':
      return '🐑';
    case 'PIG':
      return '🐖';
    case 'CHICKEN':
      return '🐔';
    case 'HORSE':
      return '🐴';
    case 'DOG':
      return '🐕';
    case 'CAT':
      return '🐈';
    case 'RABBIT':
      return '🐇';
    case 'MICE':
      return '🐁';
    case 'FISH':
      return '🐟';
    default:
      return '🐾';
  }
}

String _statusLabel(String? raw) {
  final value = (raw ?? '').trim().toUpperCase();
  if (value.isEmpty) return 'Healthy';
  if (value == 'ACTIVE') return 'Healthy';
  if (value == 'SICK') return 'Needs Care';
  if (value == 'PREGNANT') return 'Gestating';
  return value[0] + value.substring(1).toLowerCase();
}

Color _statusColor(String status) {
  final normalized = status.toLowerCase();
  if (normalized.contains('healthy')) return const Color(0xFF2E9A57);
  if (normalized.contains('gestat') || normalized.contains('pregnant')) return const Color(0xFF8A52D1);
  if (normalized.contains('care') || normalized.contains('alert') || normalized.contains('sick')) {
    return const Color(0xFFD36A25);
  }
  return const Color(0xFF2B5FB8);
}

String? _resolvePhotoUrl(String? rawUrl) {
  if (rawUrl == null || rawUrl.trim().isEmpty) {
    return null;
  }

  final url = rawUrl.trim();
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return url;
  }

  if (url.startsWith('/')) {
    return ApiBase.absolute(url);
  }

  return url;
}
