import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/animals_provider.dart';
import '../../providers/settings_provider.dart';

class AddAnimalModal extends StatefulWidget {
  const AddAnimalModal({Key? key}) : super(key: key);

  @override
  State<AddAnimalModal> createState() => _AddAnimalModalState();
}

class _AddAnimalModalState extends State<AddAnimalModal> {
  final _formKey = GlobalKey<FormState>();

  // Form field controllers
  late TextEditingController _nameController;
  late TextEditingController _tagController;
  late TextEditingController _breedController;
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  late TextEditingController _pedigreeController;
  late TextEditingController _medicalHistoryController;
  late TextEditingController _notesController;

  // Form state
  String _selectedSpecies = 'Cattle';
  DateTime? _dateOfBirth;
  bool _isMale = true;
  bool _isPregnant = false;
  bool _photoSelected = false;
  bool _submitAttempted = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _tagController = TextEditingController();
    _breedController = TextEditingController();
    _ageController = TextEditingController();
    _weightController = TextEditingController();
    _pedigreeController = TextEditingController();
    _medicalHistoryController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tagController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _pedigreeController.dispose();
    _medicalHistoryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
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
    setState(() => _submitAttempted = true);
    final formValid = _formKey.currentState!.validate();
    if (!formValid || !_photoSelected) return;

    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    // Ensure farms are loaded so we have a farmId
    if (settingsProvider.farmLocations == null) {
      await settingsProvider.fetchFarmLocations();
    }
    final farms = settingsProvider.farmLocations;
    if (farms == null || farms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No farm found. Please set up a farm first.')),
      );
      return;
    }

    final farmId = farms[0]['id'] as String;
    final animalData = <String, dynamic>{
      'farmId': farmId,
      'name': _nameController.text.trim(),
      'type': _speciesMap[_selectedSpecies] ?? _selectedSpecies.toUpperCase(),
      'gender': _isMale ? 'MALE' : 'FEMALE',
      'age': int.tryParse(_ageController.text.trim()) ?? 0,
      'weight': double.tryParse(_weightController.text.trim()) ?? 0.0,
      if (_notesController.text.trim().isNotEmpty) 'notes': _notesController.text.trim(),
      if (_tagController.text.trim().isNotEmpty) 'tagNumber': _tagController.text.trim(),
      if (_breedController.text.trim().isNotEmpty) 'breed': _breedController.text.trim(),
    };

    final animalsProvider = Provider.of<AnimalsProvider>(context, listen: false);
    final success = await animalsProvider.addAnimal(animalData);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Animal saved successfully!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(animalsProvider.error ?? 'Failed to save animal.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    // bottom padding ensures keyboard doesn't cover the field
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF6F8F6),
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
                                  text: 'SmartLivestock ',
                                  style: TextStyle(
                                    fontSize: isMobile ? 20 : 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Manager',
                                  style: TextStyle(
                                    fontSize: isMobile ? 20 : 28,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF13EC5B),
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
                              color: Colors.grey,
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
                        icon: _photoSelected ? Icons.check_circle : Icons.add_a_photo,
                        title: _photoSelected ? 'Photo Added' : 'Animal Photo *',
                        subtitle: _photoSelected ? 'Tap to change' : 'PNG, JPG · 10MB',
                        isSelected: _photoSelected,
                        hasError: _submitAttempted && !_photoSelected,
                        onTap: () => setState(() => _photoSelected = true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildUploadBox(
                        icon: Icons.videocam,
                        title: 'ID Video',
                        subtitle: 'MP4, MOV · 50MB',
                        onTap: () {},
                      ),
                    ),
                  ],
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
                                  child: _buildDropdown(
                                    label: 'Species',
                                    value: _selectedSpecies,
                                    items: ['Cattle', 'Sheep', 'Goat', 'Swine', 'Equine'],
                                    onChanged: (value) {
                                      setState(() => _selectedSpecies = value!);
                                    },
                                  ),
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
                            ),
                            _buildTextField(
                              label: 'Tag Number',
                              hint: 'SL-9001-X',
                              controller: _tagController,
                            ),
                            _buildDropdown(
                              label: 'Species',
                              value: _selectedSpecies,
                              items: ['Cattle', 'Sheep', 'Goat', 'Swine', 'Equine'],
                              onChanged: (value) {
                                setState(() => _selectedSpecies = value!);
                              },
                            ),
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
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                label: 'Age (Months)',
                                hint: '24',
                                controller: _ageController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildTextField(
                                label: 'Weight (kg)',
                                hint: '450',
                                controller: _weightController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildDateField(),
                      ]) else
                        GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                          childAspectRatio: 3.8,
                          children: [
                            _buildTextField(
                              label: 'Age (Months)',
                              hint: '24',
                              controller: _ageController,
                              keyboardType: TextInputType.number,
                            ),
                            _buildTextField(
                              label: 'Weight (kg)',
                              hint: '450',
                              controller: _weightController,
                              keyboardType: TextInputType.number,
                            ),
                            _buildDateField(),
                          ],
                        ),
                      const SizedBox(height: 24),
                      if (isMobile)
                        Column(
                          children: [
                            _buildToggle(
                              title: 'Gender',
                              subtitle: 'Male / Female',
                              value: _isMale,
                              onChanged: (value) => setState(() => _isMale = value),
                            ),
                            const SizedBox(height: 16),
                            _buildToggle(
                              title: 'Pregnancy Status',
                              subtitle: 'Toggle if currently pregnant',
                              value: _isPregnant,
                              onChanged: (value) => setState(() => _isPregnant = value),
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              label: 'Pedigree / Lineage',
                              hint: 'Mention sire and dam registration numbers...',
                              controller: _pedigreeController,
                              maxLines: 3,
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
                                  _buildToggle(
                                    title: 'Gender',
                                    subtitle: 'Male / Female',
                                    value: _isMale,
                                    onChanged: (value) => setState(() => _isMale = value),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildToggle(
                                    title: 'Pregnancy Status',
                                    subtitle: 'Toggle if currently pregnant',
                                    value: _isPregnant,
                                    onChanged: (value) => setState(() => _isPregnant = value),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _buildTextField(
                                label: 'Pedigree / Lineage',
                                hint: 'Mention sire and dam registration numbers...',
                                controller: _pedigreeController,
                                maxLines: 4,
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
                      _buildTextField(
                        label: 'Medical History',
                        hint: 'Past illnesses, vaccinations, or surgeries...',
                        controller: _medicalHistoryController,
                        maxLines: 3,
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
                Divider(color: Colors.grey[300]),
                const SizedBox(height: 16),
                Wrap(
                  alignment: isMobile ? WrapAlignment.center : WrapAlignment.end,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.grey[600],
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
                    ElevatedButton.icon(
                      onPressed: _saveAnimal,
                      icon: const Icon(Icons.save, size: 18),
                      label: const Text('Save Animal'),
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

  Widget _buildDateField() {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Date of Birth',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _dateOfBirth != null
                  ? '${_dateOfBirth!.year}-${_dateOfBirth!.month.toString().padLeft(2, '0')}-${_dateOfBirth!.day.toString().padLeft(2, '0')}'
                  : 'Select date',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF13EC5B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required bool isMobile,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
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
                  color: Colors.black,
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
    bool isSelected = false,
    bool hasError = false,
    required VoidCallback onTap,
  }) {
    final borderColor = hasError
        ? Colors.red
        : isSelected
            ? const Color(0xFF13EC5B)
            : Colors.grey[400]!;
    final iconColor = hasError
        ? Colors.red
        : isSelected
            ? const Color(0xFF13EC5B)
            : Colors.grey[400]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 2),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Center(
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
                        color: hasError ? Colors.red : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: hasError ? Colors.red[300] : Colors.grey,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildToggle({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[200]!),
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
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
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
