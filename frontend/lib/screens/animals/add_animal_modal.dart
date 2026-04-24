import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import '../../providers/animals_provider.dart';
import '../../providers/settings_provider.dart';
import 'widgets/animal_record_table_dialog.dart';

class AddAnimalModal extends StatefulWidget {
  const AddAnimalModal({Key? key}) : super(key: key);

  @override
  State<AddAnimalModal> createState() => _AddAnimalModalState();
}

class _AddAnimalModalState extends State<AddAnimalModal> {
  final _formKey = GlobalKey<FormState>();
  static const List<String> _speciesOptions = [
    'Cattle',
    'Goat',
    'Sheep',
    'Pig',
    'Chicken',
    'Horse',
    'Dog',
    'Cat',
    'Rabbit',
    'Fish',
  ];
  static const List<String> _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  // Form field controllers
  late TextEditingController _nameController;
  late TextEditingController _tagController;
  late TextEditingController _breedController;
  late TextEditingController _weightController;
  late TextEditingController _notesController;
  List<Map<String, String>> _pedigreeRecords = <Map<String, String>>[];
  List<Map<String, String>> _medicalHistoryRecords = <Map<String, String>>[];

  // Form state
  String _selectedSpecies = 'Cattle';
  String _selectedGender = 'MALE';
  int? _selectedBirthDay;
  int? _selectedBirthMonth;
  int? _selectedBirthYear;
  bool _isPregnant = false;
  bool _isUploadingPhoto = false;
  bool _isSaving = false;
  bool _submitAttempted = false;
  XFile? _selectedPhoto;
  Uint8List? _selectedPhotoBytes;
  String? _uploadedPhotoUrl;
  String? _photoUploadError;
  String? _saveError;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _tagController = TextEditingController();
    _breedController = TextEditingController();
    _weightController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tagController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<int> _intRange(int start, int endInclusive) {
    return List<int>.generate(
      endInclusive - start + 1,
      (index) => start + index,
    );
  }

  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  DateTime? _selectedDateOfBirth() {
    final day = _selectedBirthDay;
    final month = _selectedBirthMonth;
    final year = _selectedBirthYear;
    if (day == null || month == null || year == null) {
      return null;
    }

    final maxDay = _daysInMonth(year, month);
    if (day > maxDay) {
      return null;
    }

    final dob = DateTime(year, month, day);
    if (dob.isAfter(DateTime.now())) {
      return null;
    }
    return dob;
  }

  int? _calculateAgeInMonths() {
    final dob = _selectedDateOfBirth();
    if (dob == null) {
      return null;
    }

    final now = DateTime.now();
    int ageMonths = (now.year - dob.year) * 12 + (now.month - dob.month);
    if (now.day < dob.day) {
      ageMonths -= 1;
    }

    if (ageMonths < 0) {
      return null;
    }
    return ageMonths;
  }

  // Maps display species names to API enum values
  static const _speciesMap = {
    'Cattle': 'CATTLE',
    'Sheep': 'SHEEP',
    'Goat': 'GOAT',
    'Swine': 'PIG',
    'Equine': 'HORSE',
  };

  Future<void> _saveAnimal() async {
    if (_isSaving) return;

    setState(() {
      _submitAttempted = true;
      _saveError = null;
    });
    final formValid = _formKey.currentState!.validate();
    if (!formValid) return;

    final ageInMonths = _calculateAgeInMonths();
    if (ageInMonths == null) {
      setState(() {
        _saveError = 'Provide a valid date of birth (day, month, and year).';
      });
      return;
    }

    if (_selectedPhotoBytes == null) {
      return;
    }

    if (_isUploadingPhoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo is still uploading. Please wait...')),
      );
      return;
    }

    if (_uploadedPhotoUrl == null || _uploadedPhotoUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo upload failed. Tap the image to retry.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      // Always refresh farm list from API to avoid stale/cross-account farm ids.
      await settingsProvider.fetchFarmLocations();
      final farms = (settingsProvider.farmLocations ?? [])
          .whereType<Map>()
          .map((farm) => Map<String, dynamic>.from(farm))
          .where((farm) {
            final id = farm['id']?.toString() ?? '';
            return id.isNotEmpty && !id.startsWith('local-');
          })
          .toList();

      if (farms.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No owned farm found for this account. Please create a farm first.')),
        );
        return;
      }

        final activeFarmId = settingsProvider.activeFarmId;
        final farmId = activeFarmId != null && activeFarmId.isNotEmpty
          ? activeFarmId
          : farms.first['id']!.toString();
      final manualNotes = _notesController.text.trim();

      final animalData = <String, dynamic>{
        'farmId': farmId,
        'name': _nameController.text.trim(),
        'type': _speciesMap[_selectedSpecies] ?? _selectedSpecies.toUpperCase(),
        'gender': _selectedGender,
        'age': ageInMonths,
        'weight': double.tryParse(_weightController.text.trim()) ?? 0.0,
        'photoUrl': _uploadedPhotoUrl,
        if (manualNotes.isNotEmpty) 'notes': manualNotes,
        if (_pedigreeRecords.isNotEmpty) 'pedigreeRecords': _pedigreeRecords,
        if (_medicalHistoryRecords.isNotEmpty) 'medicalHistoryRecords': _medicalHistoryRecords,
        if (_tagController.text.trim().isNotEmpty) 'tagNumber': _tagController.text.trim(),
        if (_breedController.text.trim().isNotEmpty) 'breed': _breedController.text.trim(),
      };

      final animalsProvider = Provider.of<AnimalsProvider>(context, listen: false);
      final success = await animalsProvider.addAnimal(animalData);

      if (!mounted) return;
      if (success) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          _saveError = animalsProvider.error ?? 'Failed to save animal. Please review your input and try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (picked == null) return;

    final pickedBytes = await picked.readAsBytes();

    setState(() {
      _selectedPhoto = picked;
      _selectedPhotoBytes = pickedBytes;
      _isUploadingPhoto = true;
      _photoUploadError = null;
      _saveError = null;
    });

    final animalsProvider = Provider.of<AnimalsProvider>(context, listen: false);
    final uploadedUrl = await animalsProvider.uploadAnimalPhoto(picked);

    if (!mounted) return;

    if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
      setState(() {
        _uploadedPhotoUrl = uploadedUrl;
        _isUploadingPhoto = false;
        _photoUploadError = null;
      });
    } else {
      setState(() {
        _uploadedPhotoUrl = null;
        _isUploadingPhoto = false;
        _photoUploadError = animalsProvider.error ?? 'Photo upload failed';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_photoUploadError!)),
      );
    }
  }

  Future<void> _openPedigreeRecordsEditor() async {
    final rows = await showAnimalRecordTableDialog(
      context: context,
      title: 'Pedigree Table',
      subtitle: 'Capture sire, dam, and lineage records in structured rows.',
      addRowLabel: 'Add pedigree row',
      columns: pedigreeRecordColumns,
      initialRows: _pedigreeRecords,
    );

    if (!mounted || rows == null) {
      return;
    }

    setState(() {
      _pedigreeRecords = rows;
      _saveError = null;
    });
  }

  Future<void> _openMedicalHistoryRecordsEditor() async {
    final rows = await showAnimalRecordTableDialog(
      context: context,
      title: 'Medical History Table',
      subtitle: 'Capture historical health events row by row.',
      addRowLabel: 'Add medical row',
      columns: medicalHistoryRecordColumns,
      initialRows: _medicalHistoryRecords,
    );

    if (!mounted || rows == null) {
      return;
    }

    setState(() {
      _medicalHistoryRecords = rows;
      _saveError = null;
    });
  }

  String _summarizeRows(List<Map<String, String>> rows) {
    if (rows.isEmpty) {
      return 'No rows added yet';
    }

    final first = rows.first.values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .join(' | ');
    if (rows.length == 1) {
      return first.isEmpty ? '1 row saved' : first;
    }
    final suffix = rows.length - 1;
    return first.isEmpty ? '${rows.length} rows saved' : '$first (+$suffix more)';
  }

  Widget _buildStructuredTableLauncher({
    required String title,
    required String subtitle,
    required int rowCount,
    required VoidCallback onTap,
    required List<Map<String, String>> rows,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasRows = rowCount > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? colorScheme.surfaceContainerHighest.withOpacity(0.42)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.72),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hasRows
                      ? 'Rows: $rowCount · ${_summarizeRows(rows)}'
                      : 'Rows: 0 · ${_summarizeRows(rows)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: hasRows ? const Color(0xFF13EC5B) : colorScheme.onSurface.withOpacity(0.64),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: onTap,
            icon: Icon(hasRows ? Icons.edit : Icons.table_chart_outlined, size: 17),
            label: Text(hasRows ? 'Edit Table' : 'Open Table'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF13EC5B),
              foregroundColor: Colors.black,
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 768;

    // bottom padding ensures keyboard doesn't cover the field
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surface : const Color(0xFFF6F8F6),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          constraints: BoxConstraints(
            maxWidth: isMobile ? double.infinity : 900,
          ),
          padding: EdgeInsets.fromLTRB(
            isMobile ? 16 : 32,
            isMobile ? 16 : 32,
            isMobile ? 16 : 32,
            16 + bottomInset,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF13EC5B).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.pets,
                        color: Color(0xFF13EC5B),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Register',
                                  style: TextStyle(
                                    fontSize: isMobile ? 20 : 28,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Register a new individual to the herd database',
                            style: TextStyle(
                              fontSize: isMobile ? 12 : 14,
                              color: colorScheme.onSurface.withOpacity(0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Media Upload Section
                Row(
                  children: [
                    Expanded(
                      child: _buildUploadBox(
                        icon: _isUploadingPhoto
                            ? Icons.cloud_upload
                            : _selectedPhotoBytes != null
                                ? Icons.check_circle
                                : Icons.add_a_photo,
                        title: _isUploadingPhoto
                            ? 'Uploading...'
                            : _selectedPhotoBytes != null
                                ? 'Photo Added'
                                : 'Animal Photo *',
                        subtitle: _isUploadingPhoto
                            ? 'Sending to cloud storage'
                            : _selectedPhotoBytes != null
                                ? (_selectedPhoto?.name ?? 'Tap to change')
                                : 'PNG, JPG · 10MB',
                        previewBytes: _selectedPhotoBytes,
                        isSelected: _selectedPhotoBytes != null,
                        hasError: _submitAttempted && _selectedPhotoBytes == null,
                        onTap: _isUploadingPhoto ? () {} : _pickAndUploadPhoto,
                      ),
                    ),
                  ],
                ),
                if (_photoUploadError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Text(
                      _photoUploadError!,
                      style: TextStyle(fontSize: 11, color: Colors.red[700]),
                    ),
                  ),
                const SizedBox(height: 16),
                // General Information Section
                _buildSection(
                  icon: Icons.info,
                  title: 'General Identification',
                  isMobile: isMobile,
                  child: isMobile
                      ? Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    label: 'Animal Name',
                                    hint: 'e.g. Bessie',
                                    controller: _nameController,
                                    isRequired: true,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildTextField(
                                    label: 'Tag Number',
                                    hint: 'SL-9001-X',
                                    controller: _tagController,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSpeciesSelector(label: 'Species'),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildTextField(
                                    label: 'Breed',
                                    hint: 'e.g. Holstein',
                                    controller: _breedController,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                          childAspectRatio: 3.8,
                          children: [
                            _buildTextField(
                              label: 'Animal Name',
                              hint: 'e.g. Bessie',
                              controller: _nameController,
                              isRequired: true,
                            ),
                            _buildTextField(
                              label: 'Tag Number',
                              hint: 'SL-9001-X',
                              controller: _tagController,
                            ),
                            _buildSpeciesSelector(label: 'Species'),
                            _buildTextField(
                              label: 'Breed',
                              hint: 'e.g. Holstein-Friesian',
                              controller: _breedController,
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 16),
                // Biological Profile Section
                _buildSection(
                  icon: Icons.monitor_weight,
                  title: 'Biological Profile',
                  isMobile: isMobile,
                  child: Column(
                    children: [
                      if (isMobile) ...([
                        _buildTextField(
                          label: 'Weight (kg)',
                          hint: '450',
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                        const SizedBox(height: 12),
                        _buildDateOfBirthDropdown(),
                        const SizedBox(height: 12),
                        _buildDerivedAgeDisplay(),
                      ]) else
                        Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    label: 'Weight (kg)',
                                    hint: '450',
                                    controller: _weightController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: _buildDateOfBirthDropdown(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildDerivedAgeDisplay(),
                          ],
                        ),
                      const SizedBox(height: 24),
                      if (isMobile)
                        Column(
                          children: [
                            _buildGenderDropdown(),
                            if (_selectedGender == 'FEMALE') ...[
                              const SizedBox(height: 16),
                              _buildToggle(
                                title: 'Pregnancy Status',
                                subtitle: 'Toggle if currently pregnant',
                                value: _isPregnant,
                                onChanged: (value) => setState(() => _isPregnant = value),
                              ),
                            ],
                            const SizedBox(height: 12),
                            _buildStructuredTableLauncher(
                              title: 'Pedigree / Lineage',
                              subtitle: 'Use table rows for sire, dam, and related lineage.',
                              rowCount: _pedigreeRecords.length,
                              rows: _pedigreeRecords,
                              onTap: _openPedigreeRecordsEditor,
                            ),
                          ],
                        )
                      else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  _buildGenderDropdown(),
                                  if (_selectedGender == 'FEMALE') ...[
                                    const SizedBox(height: 16),
                                    _buildToggle(
                                      title: 'Pregnancy Status',
                                      subtitle: 'Toggle if currently pregnant',
                                      value: _isPregnant,
                                      onChanged: (value) => setState(() => _isPregnant = value),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _buildStructuredTableLauncher(
                                title: 'Pedigree / Lineage',
                                subtitle: 'Use table rows for sire, dam, and related lineage.',
                                rowCount: _pedigreeRecords.length,
                                rows: _pedigreeRecords,
                                onTap: _openPedigreeRecordsEditor,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Health & History Section
                _buildSection(
                  icon: Icons.medical_services,
                  title: 'Health & History',
                  isMobile: isMobile,
                  child: Column(
                    children: [
                      _buildStructuredTableLauncher(
                        title: 'Medical History',
                        subtitle: 'Use table rows for treatment dates, conditions, and outcomes.',
                        rowCount: _medicalHistoryRecords.length,
                        rows: _medicalHistoryRecords,
                        onTap: _openMedicalHistoryRecordsEditor,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        label: 'General Notes',
                        hint: 'Behavioral notes, specific dietary needs, etc.',
                        controller: _notesController,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Action Footer
                Divider(color: colorScheme.outline.withOpacity(0.35)),
                const SizedBox(height: 16),
                if (_isSaving)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Saving animal record...',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_saveError != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.error.withOpacity(0.35)),
                    ),
                    child: Text(
                      _saveError!,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Wrap(
                  alignment: isMobile ? WrapAlignment.center : WrapAlignment.end,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: colorScheme.onSurface.withOpacity(0.75),
                        elevation: 0,
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 24 : 32,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Discard Draft',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveAnimal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF13EC5B),
                        foregroundColor: Colors.black,
                        elevation: 8,
                        shadowColor: const Color(0xFF13EC5B).withOpacity(0.3),
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 24 : 40,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSaving
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Saving...'),
                              ],
                            )
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.save, size: 18),
                                SizedBox(width: 8),
                                Text('Save Animal'),
                              ],
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateOfBirthDropdown() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentYear = DateTime.now().year;
    final years = _intRange(currentYear - 80, currentYear).reversed.toList();
    final selectedYear = _selectedBirthYear ?? currentYear;
    final selectedMonth = _selectedBirthMonth ?? 1;
    final dayLimit = _daysInMonth(selectedYear, selectedMonth);
    final days = _intRange(1, dayLimit);

    final labelStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface.withOpacity(0.85),
    );

    InputDecoration dropdownDecoration(String hint) {
      return InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: colorScheme.onSurface.withOpacity(0.65),
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.35)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: Color(0xFF13EC5B), width: 1.4),
        ),
        fillColor: theme.brightness == Brightness.dark
            ? colorScheme.surfaceContainerHighest.withOpacity(0.42)
            : colorScheme.surface,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Date of Birth *', style: labelStyle),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _selectedBirthDay,
                validator: (_) => _selectedDateOfBirth() == null ? 'Day' : null,
                items: days
                    .map((day) => DropdownMenuItem<int>(value: day, child: Text(day.toString())))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBirthDay = value;
                    _saveError = null;
                  });
                },
                decoration: dropdownDecoration('Day'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _selectedBirthMonth,
                validator: (value) => value == null ? 'Month' : null,
                items: List<int>.generate(12, (index) => index + 1)
                    .map(
                      (month) => DropdownMenuItem<int>(
                        value: month,
                        child: Text(_monthNames[month - 1]),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedBirthMonth = value;
                    final year = _selectedBirthYear ?? currentYear;
                    final maxDay = _daysInMonth(year, value);
                    if (_selectedBirthDay != null && _selectedBirthDay! > maxDay) {
                      _selectedBirthDay = maxDay;
                    }
                    _saveError = null;
                  });
                },
                decoration: dropdownDecoration('Month'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _selectedBirthYear,
                validator: (value) => value == null ? 'Year' : null,
                items: years
                    .map(
                      (year) => DropdownMenuItem<int>(
                        value: year,
                        child: Text(year.toString()),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedBirthYear = value;
                    final month = _selectedBirthMonth ?? 1;
                    final maxDay = _daysInMonth(value, month);
                    if (_selectedBirthDay != null && _selectedBirthDay! > maxDay) {
                      _selectedBirthDay = maxDay;
                    }
                    _saveError = null;
                  });
                },
                decoration: dropdownDecoration('Year'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDerivedAgeDisplay() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ageInMonths = _calculateAgeInMonths();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? colorScheme.surfaceContainerHighest.withOpacity(0.34)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, size: 18, color: colorScheme.onSurface.withOpacity(0.78)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              ageInMonths == null
                  ? 'Age will auto-calculate after selecting date of birth'
                  : 'Auto-calculated age: $ageInMonths months',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withOpacity(0.84),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required bool isMobile,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? colorScheme.surfaceContainerHighest.withOpacity(0.36)
            : colorScheme.surface,
        border: Border.all(color: colorScheme.outline.withOpacity(0.35)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF13EC5B).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: const Color(0xFF13EC5B), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 20),
          child,
        ],
      ),
    );
  }

  Widget _buildUploadBox({
    required IconData icon,
    required String title,
    required String subtitle,
    Uint8List? previewBytes,
    bool isSelected = false,
    bool hasError = false,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderColor = hasError
        ? Colors.red
        : isSelected
            ? const Color(0xFF13EC5B)
        : colorScheme.outline.withOpacity(0.45);
    final iconColor = hasError
        ? Colors.red
        : isSelected
            ? const Color(0xFF13EC5B)
        : colorScheme.onSurface.withOpacity(0.55);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: previewBytes != null ? 190 : 100,
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 2),
            borderRadius: BorderRadius.circular(12),
            color: theme.brightness == Brightness.dark
                ? colorScheme.surfaceContainerHighest.withOpacity(0.35)
                : colorScheme.surface,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: previewBytes != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            previewBytes,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 28, color: iconColor),
                          const SizedBox(height: 6),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: hasError
                                  ? Colors.red
                                  : colorScheme.onSurface.withOpacity(0.9),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 11,
                              color: hasError
                                  ? Colors.red[300]
                                  : colorScheme.onSurface.withOpacity(0.65),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
              ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              'Photo is required',
              style: TextStyle(fontSize: 11, color: Colors.red[700]),
            ),
          ),
        if (previewBytes != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              'Tap image or pen icon to change',
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurface.withOpacity(0.68),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.86),
            ),
            children: isRequired
                ? const [TextSpan(text: ' *', style: TextStyle(color: Colors.red))]
                : [],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: isRequired
              ? (value) => (value == null || value.trim().isEmpty) ? 'Required' : null
              : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.65),
              fontWeight: FontWeight.w400,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.35)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: Color(0xFF13EC5B), width: 1.4),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.error, width: 1.4),
            ),
            fillColor: theme.brightness == Brightness.dark
                ? colorScheme.surfaceContainerHighest.withOpacity(0.42)
                : colorScheme.surface,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderDropdown() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withOpacity(0.86),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedGender,
          items: const [
            DropdownMenuItem(value: 'MALE', child: Text('Male')),
            DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selectedGender = value;
              if (_selectedGender == 'MALE') {
                _isPregnant = false;
              }
            });
          },
          decoration: InputDecoration(
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.35)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: Color(0xFF13EC5B), width: 1.4),
            ),
            fillColor: theme.brightness == Brightness.dark
                ? colorScheme.surfaceContainerHighest.withOpacity(0.42)
                : colorScheme.surface,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeciesSelector({required String label}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withOpacity(0.86),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showSpeciesPicker,
          borderRadius: BorderRadius.circular(8),
          child: InputDecorator(
            decoration: InputDecoration(
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.35)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFF13EC5B), width: 1.4),
              ),
              fillColor: theme.brightness == Brightness.dark
                  ? colorScheme.surfaceContainerHighest.withOpacity(0.42)
                  : colorScheme.surface,
              filled: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedSpecies,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withOpacity(0.9),
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: colorScheme.onSurface.withOpacity(0.8)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showSpeciesPicker() async {
    String query = '';

    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = _speciesOptions
                .where((species) => species.toLowerCase().contains(query.toLowerCase()))
                .toList();

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: SizedBox(
                  height: 420,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Species',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        autofocus: true,
                        onChanged: (value) => setModalState(() => query = value),
                        decoration: const InputDecoration(
                          hintText: 'Search species',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(child: Text('No species found'))
                            : ListView.builder(
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final species = filtered[index];
                                  return ListTile(
                                    title: Text(species),
                                    trailing: species == _selectedSpecies
                                        ? const Icon(Icons.check, color: Color(0xFF13EC5B))
                                        : null,
                                    onTap: () => Navigator.pop(sheetContext, species),
                                  );
                                },
                              ),
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

    if (selected != null && selected != _selectedSpecies) {
      setState(() => _selectedSpecies = selected);
    }
  }

  Widget _buildToggle({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? colorScheme.surfaceContainerHighest.withOpacity(0.34)
            : colorScheme.surface,
        border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withOpacity(0.72),
                ),
              ),
            ],
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF13EC5B),
          ),
        ],
      ),
    );
  }
}
