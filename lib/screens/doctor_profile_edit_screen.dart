import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/common_widgets.dart';
import '../models/doctor_model.dart';
import '../theme/app_theme.dart';

class DoctorProfileEditScreen extends StatefulWidget {
  const DoctorProfileEditScreen({Key? key}) : super(key: key);

  @override
  State<DoctorProfileEditScreen> createState() => _DoctorProfileEditScreenState();
}

class _DoctorProfileEditScreenState extends State<DoctorProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _clinicController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _licenseController = TextEditingController();
  final _aboutController = TextEditingController();
  final _feeController = TextEditingController();
  final _experienceController = TextEditingController();

  String _selectedSpecialization = 'Cardiologist';
  List<String> _selectedDays = [];
  Map<String, List<String>> _availableTimes = {};
  List<String> _qualifications = [];
  final _qualificationController = TextEditingController();
  bool _isLoading = false;

  final List<String> _specializations = [
    'Cardiologist',
    'Dermatologist',
    'Pediatrician',
    'Orthopedist',
    'Neurologist',
    'Psychiatrist',
    'Gynecologist',
    'Ophthalmologist',
    'ENT Specialist',
    'General Physician',
  ];

  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final List<String> _timeSlots = [
    '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
    '12:00', '12:30', '14:00', '14:30', '15:00', '15:30',
    '16:00', '16:30', '17:00', '17:30', '18:00', '18:30',
  ];

  @override
  void initState() {
    super.initState();
    _loadDoctorData();
  }

  Future<void> _loadDoctorData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _nameController.text = data['name'] ?? '';
        _clinicController.text = data['clinic'] ?? '';
        _phoneController.text = data['phoneNumber'] ?? '';
        _addressController.text = data['address'] ?? '';
        _licenseController.text = data['licenseNumber'] ?? '';
        _aboutController.text = data['about'] ?? '';
        _feeController.text = data['consultationFee']?.toString() ?? '';
        _experienceController.text = data['experienceYears']?.toString() ?? '';
        _selectedSpecialization = data['specialization'] ?? 'Cardiologist';
        _selectedDays = List<String>.from(data['availableDays'] ?? []);
        _availableTimes = Map<String, List<String>>.from(data['availableTimes'] ?? {});
        _qualifications = List<String>.from(data['qualifications'] ?? []);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _clinicController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _licenseController.dispose();
    _aboutController.dispose();
    _feeController.dispose();
    _experienceController.dispose();
    _qualificationController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doctorData = {
        'name': _nameController.text.trim(),
        'specialization': _selectedSpecialization,
        'clinic': _clinicController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'licenseNumber': _licenseController.text.trim(),
        'about': _aboutController.text.trim(),
        'consultationFee': double.tryParse(_feeController.text) ?? 0.0,
        'experienceYears': int.tryParse(_experienceController.text) ?? 0,
        'availableDays': _selectedDays,
        'availableTimes': _availableTimes,
        'qualifications': _qualifications,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(user.uid)
          .update(doctorData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addQualification() {
    if (_qualificationController.text.trim().isNotEmpty) {
      setState(() {
        _qualifications.add(_qualificationController.text.trim());
        _qualificationController.clear();
      });
    }
  }

  void _removeQualification(int index) {
    setState(() {
      _qualifications.removeAt(index);
    });
  }

  void _toggleDay(String day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
        _availableTimes.remove(day);
      } else {
        _selectedDays.add(day);
        _availableTimes[day] = [];
      }
    });
  }

  void _toggleTimeSlot(String day, String time) {
    setState(() {
      if (_availableTimes[day]?.contains(time) ?? false) {
        _availableTimes[day]!.remove(time);
      } else {
        _availableTimes[day] ??= [];
        _availableTimes[day]!.add(time);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information
              _buildSectionTitle('Basic Information'),
              AppTextField(
                controller: _nameController,
                label: 'Full Name',
                validator: (value) => value?.isEmpty == true ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedSpecialization,
                decoration: const InputDecoration(
                  labelText: 'Specialization',
                  border: OutlineInputBorder(),
                ),
                items: _specializations.map((String specialization) {
                  return DropdownMenuItem<String>(
                    value: specialization,
                    child: Text(specialization),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedSpecialization = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _clinicController,
                label: 'Hospital/Clinic Name',
                validator: (value) => value?.isEmpty == true ? 'Clinic name is required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _phoneController,
                label: 'Phone Number',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _addressController,
                label: 'Address',
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _licenseController,
                label: 'License Number',
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _aboutController,
                label: 'About',
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _feeController,
                      label: 'Consultation Fee',
                      keyboardType: TextInputType.number,
                      validator: (value) => value?.isEmpty == true ? 'Fee is required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppTextField(
                      controller: _experienceController,
                      label: 'Experience (Years)',
                      keyboardType: TextInputType.number,
                      validator: (value) => value?.isEmpty == true ? 'Experience is required' : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Qualifications'),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _qualificationController,
                      label: 'Add Qualification',
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addQualification,
                    child: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._qualifications.asMap().entries.map((entry) {
                return Card(
                  child: ListTile(
                    title: Text(entry.value),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _removeQualification(entry.key),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 24),
              _buildSectionTitle('Available Days & Times'),
              Wrap(
                spacing: 8,
                children: _daysOfWeek.map((day) {
                  final isSelected = _selectedDays.contains(day);
                  return FilterChip(
                    label: Text(day),
                    selected: isSelected,
                    onSelected: (_) => _toggleDay(day),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),
              ..._selectedDays.map((day) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          day,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: _timeSlots.map((time) {
                            final isSelected = _availableTimes[day]?.contains(time) ?? false;
                            return FilterChip(
                              label: Text(time),
                              selected: isSelected,
                              onSelected: (_) => _toggleTimeSlot(day, time),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }
}
