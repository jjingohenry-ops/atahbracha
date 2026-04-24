import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddAnimalScreen extends StatefulWidget {
  const AddAnimalScreen({super.key});

  @override
  State<AddAnimalScreen> createState() => _AddAnimalScreenState();
}

class _AddAnimalScreenState extends State<AddAnimalScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
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
  
  // Controllers
  final _nameController = TextEditingController();
  final _tagController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _pedigreeController = TextEditingController();
  final _medicalController = TextEditingController();
  final _notesController = TextEditingController();
  
  // Variables
  String? _selectedSpecies;
  DateTime? _dateOfBirth;
  bool _isMale = true;
  bool _isPregnant = false;
  File? _animalImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _tagController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _pedigreeController.dispose();
    _medicalController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F8F6),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, color: Colors.black87),
        ),
        title: const Text(
          'Add Animal',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
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
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            children: [
                              TextSpan(text: 'Register'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Register a new individual to the herd database',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Media Upload Section
              _buildMediaUploadSection(),
              
              const SizedBox(height: 32),
              
              // General Information
              _buildGeneralInfoSection(),
              
              const SizedBox(height: 32),
              
              // Physical & Biological Details
              _buildBiologicalProfileSection(),
              
              const SizedBox(height: 32),
              
              // Health & Records
              _buildHealthSection(),
              
              const SizedBox(height: 32),
              
              // Action Buttons
              _buildActionButtons(),
              
              const SizedBox(height: 32),
              
              // Footer
              Center(
                child: Text(
                  '© 2024 Atahbracah Management Systems. All rights reserved.',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaUploadSection() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey[300]!,
            style: BorderStyle.solid,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: _animalImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  _animalImage!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo,
                    size: 32,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload Animal Photo',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    'PNG, JPG up to 10MB',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildGeneralInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info,
                color: Color(0xFF13EC5B),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'General Identification',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _nameController,
                  decoration: _buildInputDecoration('Animal Name', 'e.g. Bessie'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter animal name';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _tagController,
                  decoration: _buildInputDecoration('Tag Number', 'SL-9001-X'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter tag number';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: FormField<String>(
                  initialValue: _selectedSpecies,
                  validator: (value) {
                    if ((_selectedSpecies ?? '').isEmpty) {
                      return 'Please select species';
                    }
                    return null;
                  },
                  builder: (field) {
                    return InkWell(
                      onTap: () async {
                        final selected = await _showSpeciesPicker();
                        if (selected != null) {
                          setState(() => _selectedSpecies = selected);
                          field.didChange(selected);
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: InputDecorator(
                        decoration: _buildInputDecoration('Species', 'Search and select species').copyWith(
                          errorText: field.errorText,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selectedSpecies ?? 'Search and select species',
                                style: TextStyle(
                                  color: _selectedSpecies == null
                                      ? Colors.grey.withOpacity(0.35)
                                      : Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, color: Colors.black54),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _breedController,
                  decoration: _buildInputDecoration('Breed', 'e.g. Holstein-Friesian'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter breed';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBiologicalProfileSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.monitor_weight,
                color: Color(0xFF13EC5B),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Biological Profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _ageController,
                  decoration: _buildInputDecoration('Age (Months)', '24'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter age';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _weightController,
                  decoration: _buildInputDecoration('Weight (kg)', '450'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter weight';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: _selectDateOfBirth,
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: _buildInputDecoration(
                        'Date of Birth',
                        _dateOfBirth != null
                            ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                            : 'Select date',
                      ),
                      validator: (value) {
                        if (_dateOfBirth == null) {
                          return 'Please select date of birth';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Toggle Controls
              Expanded(
                child: Column(
                  children: [
                    _buildToggleControl(
                      'Gender',
                      'Male / Female',
                      _isMale,
                      (value) => setState(() {
                        _isMale = value;
                        if (_isMale) {
                          _isPregnant = false;
                        }
                      }),
                    ),
                    if (!_isMale) ...[
                      const SizedBox(height: 16),
                      _buildToggleControl(
                        'Pregnancy Status',
                        'Toggle if currently pregnant',
                        _isPregnant,
                        (value) => setState(() => _isPregnant = value),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(width: 32),
              
              // Pedigree Info
              Expanded(
                child: TextFormField(
                  controller: _pedigreeController,
                  decoration: _buildInputDecoration(
                    'Pedigree / Lineage',
                    'Mention sire and dam registration numbers...',
                  ).copyWith(
                    hintText: 'Mention sire and dam registration numbers...',
                  ),
                  maxLines: 4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.medical_services,
                color: Color(0xFF13EC5B),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Health & History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          TextFormField(
            controller: _medicalController,
            decoration: _buildInputDecoration(
              'Medical History',
              'Past illnesses, vaccinations, or surgeries...',
            ).copyWith(
              hintText: 'Past illnesses, vaccinations, or surgeries...',
            ),
            maxLines: 3,
          ),
          
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _notesController,
            decoration: _buildInputDecoration(
              'General Notes',
              'Behavioral notes, specific dietary needs, etc.',
            ).copyWith(
              hintText: 'Behavioral notes, specific dietary needs, etc.',
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.only(top: 24),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              backgroundColor: Colors.grey[200],
              foregroundColor: Colors.grey[700],
            ),
            child: const Text(
              'Discard Draft',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _saveAnimal,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(_isLoading ? 'Saving...' : 'Save Animal'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF13EC5B),
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              elevation: 8,
              shadowColor: const Color(0xFF13EC5B).withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleControl(
    String title,
    String description,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
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
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
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

  InputDecoration _buildInputDecoration(String label, String placeholder) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.w500,
      ),
      hintText: placeholder,
      hintStyle: TextStyle(
        color: Colors.grey.withOpacity(0.35),
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF13EC5B), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 600,
      imageQuality: 80,
    );
    
    if (pickedFile != null) {
      setState(() {
        _animalImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  Future<String?> _showSpeciesPicker() async {
    String query = '';

    return showModalBottomSheet<String>(
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
  }

  Future<void> _saveAnimal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // TODO: Implement API call to save animal
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Animal saved successfully!'),
            backgroundColor: Color(0xFF13EC5B),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving animal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
