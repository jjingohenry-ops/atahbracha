import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/network/api_base.dart';
import '../../providers/animals_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';

class AnimalsScreen extends StatefulWidget {
  const AnimalsScreen({super.key});

  @override
  State<AnimalsScreen> createState() => _AnimalsScreenState();
}

class _AnimalsScreenState extends State<AnimalsScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';

  final List<String> _filters = [
    'All',
    'CATTLE',
    'GOAT',
    'SHEEP',
    'PIG',
    'CHICKEN',
    'HORSE',
    'DOG',
    'CAT',
    'RABBIT',
    'MICE',
    'FISH',
    'OTHER',
  ];
  final ImagePicker _imagePicker = ImagePicker();

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
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.user == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            _buildSearchAndFilter(),
            Expanded(child: _buildAnimalList()),
          ],
        );
      },
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              hintText: 'Search animals...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((filter) {
                final isSelected = filter == _selectedFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter == 'All' ? 'All' : _formatType(filter)),
                    selected: isSelected,
                    onSelected: (selected) =>
                        setState(() => _selectedFilter = selected ? filter : _selectedFilter),
                    backgroundColor: Colors.grey[200],
                    selectedColor: const Color(0xFF13EC5B),
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFF102216) : Colors.grey[600],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimalList() {
    return Consumer<AnimalsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.error != null) {
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
                    Text(provider.error!, style: TextStyle(fontSize: 13, color: Colors.red[600]), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        final settingsProvider =
                            Provider.of<SettingsProvider>(context, listen: false);
                        provider.fetchAnimals(farmId: settingsProvider.activeFarmId);
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

        final filtered = (provider.animals as List).where((a) {
          final name = (a['name'] ?? '').toString().toLowerCase();
          final type = (a['type'] ?? '').toString().toUpperCase();
          final matchesSearch = name.contains(_searchQuery.toLowerCase());
          final matchesFilter = _selectedFilter == 'All' || type == _selectedFilter;
          return matchesSearch && matchesFilter;
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.pets, size: 56, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('No animals found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[600])),
                const SizedBox(height: 8),
                Text('Add your first animal using the + button', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final animal = filtered[index] as Map<String, dynamic>;
            return _buildAnimalCard(animal);
          },
        );
      },
    );
  }

  Widget _buildAnimalCard(Map<String, dynamic> animal) {
    final type = (animal['type'] ?? 'UNKNOWN').toString();
    final gender = (animal['gender'] ?? '').toString();
    final weight = animal['weight'];
    final age = animal['age'];
    final photoUrl = _resolvePhotoUrl(animal['photoUrl']?.toString());

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showAnimalDetailsModal(animal),
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF13EC5B).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: photoUrl != null
                      ? Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          width: 64,
                          height: 64,
                          webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(_animalEmoji(type), style: const TextStyle(fontSize: 28)),
                          ),
                        )
                      : Center(
                          child: Text(_animalEmoji(type), style: const TextStyle(fontSize: 28)),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            animal['name'] ?? 'Unknown',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF102216)),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF13EC5B),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _formatType(type),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF102216)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (age != null) ...[
                          Icon(Icons.cake_outlined, size: 13, color: Colors.grey[500]),
                          const SizedBox(width: 3),
                          Text('$age yrs', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          const SizedBox(width: 12),
                        ],
                        if (weight != null) ...[
                          Icon(Icons.monitor_weight_outlined, size: 13, color: Colors.grey[500]),
                          const SizedBox(width: 3),
                          Text('${weight}kg', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          const SizedBox(width: 12),
                        ],
                        if (gender.isNotEmpty) ...[
                          Icon(
                            gender.toUpperCase() == 'MALE' ? Icons.male : Icons.female,
                            size: 13,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 3),
                          Text(
                            gender[0].toUpperCase() + gender.substring(1).toLowerCase(),
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ],
                    ),
                    if (animal['notes'] != null && (animal['notes'] as String).isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        animal['notes'],
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAnimalDetailsModal(Map<String, dynamic> animal) async {
    final nameController = TextEditingController(text: (animal['name'] ?? '').toString());
    final ageController = TextEditingController(text: (animal['age'] ?? '').toString());
    final weightController = TextEditingController(text: (animal['weight'] ?? '').toString());
    final notesController = TextEditingController(text: (animal['notes'] ?? '').toString());

    String selectedType = (animal['type'] ?? 'CATTLE').toString().toUpperCase();
    String selectedGender = (animal['gender'] ?? 'MALE').toString().toUpperCase();
    String? currentPhotoUrl = animal['photoUrl']?.toString();
    bool isSaving = false;
    bool isUploading = false;
    String? dialogError;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Animal Details',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            onPressed: isSaving ? null : () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: isUploading
                              ? null
                              : () async {
                                  final picked = await _imagePicker.pickImage(
                                    source: ImageSource.gallery,
                                    maxWidth: 1920,
                                    maxHeight: 1920,
                                    imageQuality: 85,
                                  );
                                  if (picked == null) {
                                    return;
                                  }

                                  setDialogState(() {
                                    isUploading = true;
                                    dialogError = null;
                                  });

                                  final provider = Provider.of<AnimalsProvider>(context, listen: false);
                                  final uploadedUrl = await provider.uploadAnimalPhoto(picked);

                                  if (!mounted) {
                                    return;
                                  }

                                  setDialogState(() {
                                    isUploading = false;
                                    if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
                                      currentPhotoUrl = uploadedUrl;
                                    } else {
                                      dialogError = provider.error ?? 'Failed to upload image';
                                    }
                                  });
                                },
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: const Color(0xFF13EC5B).withOpacity(0.12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: _resolvePhotoUrl(currentPhotoUrl) != null
                                  ? Image.network(
                                      _resolvePhotoUrl(currentPhotoUrl)!,
                                      fit: BoxFit.cover,
                                      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                                      errorBuilder: (_, __, ___) => Center(
                                        child: Text(
                                          _animalEmoji(selectedType),
                                          style: const TextStyle(fontSize: 42),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        _animalEmoji(selectedType),
                                        style: const TextStyle(fontSize: 42),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          isUploading ? 'Uploading image...' : 'Tap image to change',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        items: _filters
                            .where((e) => e != 'All')
                            .map(
                              (type) => DropdownMenuItem<String>(
                                value: type,
                                child: Text(_formatType(type)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => selectedType = value);
                          }
                        },
                        decoration: const InputDecoration(labelText: 'Type'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedGender,
                        items: const [
                          DropdownMenuItem(value: 'MALE', child: Text('Male')),
                          DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => selectedGender = value);
                          }
                        },
                        decoration: const InputDecoration(labelText: 'Gender'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: ageController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Age'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: weightController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Weight (kg)'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: notesController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(labelText: 'Notes'),
                      ),
                      if (dialogError != null) ...[
                        const SizedBox(height: 12),
                        Text(dialogError!, style: const TextStyle(color: Colors.red)),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSaving ? null : () => Navigator.of(dialogContext).pop(),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isSaving || isUploading
                                  ? null
                                  : () async {
                                      final animalId = animal['id']?.toString();
                                      if (animalId == null || animalId.isEmpty) {
                                        setDialogState(() => dialogError = 'Missing animal id');
                                        return;
                                      }

                                      final parsedAge = int.tryParse(ageController.text.trim());
                                      final parsedWeight = double.tryParse(weightController.text.trim());

                                      if (nameController.text.trim().isEmpty || parsedAge == null || parsedWeight == null) {
                                        setDialogState(() => dialogError = 'Name, age and weight are required');
                                        return;
                                      }

                                      setDialogState(() {
                                        isSaving = true;
                                        dialogError = null;
                                      });

                                      final settings = Provider.of<SettingsProvider>(context, listen: false);
                                      final provider = Provider.of<AnimalsProvider>(context, listen: false);
                                      final success = await provider.updateAnimal(
                                        animalId,
                                        {
                                          'name': nameController.text.trim(),
                                          'type': selectedType,
                                          'gender': selectedGender,
                                          'age': parsedAge,
                                          'weight': parsedWeight,
                                          'notes': notesController.text.trim(),
                                          'photoUrl': currentPhotoUrl,
                                        },
                                        farmId: settings.activeFarmId,
                                      );

                                      if (!mounted) {
                                        return;
                                      }

                                      if (success) {
                                        Navigator.of(dialogContext).pop();
                                      } else {
                                        setDialogState(() {
                                          isSaving = false;
                                          dialogError = provider.error ?? 'Failed to update animal';
                                        });
                                      }
                                    },
                              child: isSaving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Save Changes'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    ageController.dispose();
    weightController.dispose();
    notesController.dispose();
  }

  String _formatType(String type) {
    if (type.isEmpty) return type;
    final normalized = type.toUpperCase();
    switch (normalized) {
      case 'COW':
        return 'Cow';
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
      case 'OTHER':
        return 'Other';
      default:
        return type[0].toUpperCase() + type.substring(1).toLowerCase();
    }
  }

  String _animalEmoji(String type) {
    switch (type.toUpperCase()) {
      case 'COW':
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
      case 'MOUSE':
        return '🐁';
      case 'FISH':
        return '🐟';
      case 'OTHER':
        return '🐾';
      default:
        return '🐾';
    }
  }

  String? _resolvePhotoUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) {
      return null;
    }

    final url = rawUrl.trim();
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    // Support backend-relative paths like /uploads/...
    if (url.startsWith('/')) {
      return ApiBase.absolute(url);
    }

    return url;
  }
}
