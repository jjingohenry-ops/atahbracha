import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/reminders_provider.dart';
import '../../providers/settings_provider.dart';

class NewReminderSheet extends StatefulWidget {
  const NewReminderSheet({Key? key}) : super(key: key);

  @override
  State<NewReminderSheet> createState() => _NewReminderSheetState();
}

class _NewReminderSheetState extends State<NewReminderSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime? _date;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _timeController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_date == null) {
      _showErrorDialog('Date Required', 'Please select a date');
      return;
    }
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final provider = Provider.of<RemindersProvider>(context, listen: false);
      // prepare payload mapping to backend treatment fields
      final reminder = {
        'title': _titleController.text,
        'dosage': _locationController.text.isNotEmpty ? _locationController.text : null,
        'time': _timeController.text.isNotEmpty ? _timeController.text : null,
        'date': _date!.toIso8601String(),
        'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
      };
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      final success = await provider.addReminder(
        reminder,
        farmId: settingsProvider.activeFarmId,
      );
      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          Navigator.pop(context);
        } else {
          _showErrorDialog(
            'Failed to Add Reminder',
            provider.error ?? 'An unexpected error occurred.',
          );
        }
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'New Reminder',
                style: TextStyle(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickDate,
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: TextEditingController(
                              text: _date == null
                                  ? ''
                                  : '${_date!.year}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}'),
                          decoration: const InputDecoration(
                              labelText: 'Date',
                              suffixIcon: Icon(Icons.calendar_today)),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _timeController,
                      decoration: const InputDecoration(labelText: 'Time (e.g. 08:00 AM)'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(labelText: 'Location / Dosage'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(labelText: 'Notes'),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isLoading ? Colors.grey[400] : const Color(0xFF13EC5B),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                    : const Text('Save Reminder'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
