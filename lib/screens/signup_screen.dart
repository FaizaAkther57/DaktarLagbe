import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/common_widgets.dart';
import 'home_screen.dart';
import 'doctor_home_screen.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  // Doctor-only fields
  final _clinicController = TextEditingController();
  final _experienceController = TextEditingController();
  final _aboutController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _feesController = TextEditingController();
  final List<String> _specialties = const <String>[
    'General Physician',
    'Cardiologist',
    'Dermatologist',
    'Pediatrician',
    'Neurologist',
    'Orthopedic',
    'Dentist',
    'ENT Specialist',
    'Gynecologist',
  ];
  String _specialization = 'General Physician';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _error;
  String _role = 'patient';

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Create user with email and password
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Create account in appropriate collection based on role
      if (_role == 'doctor') {
        // Create doctor account in doctors collection
        final String name = _nameController.text.trim();
        final String lower = name.toLowerCase();
        final List<String> tokens = <String>[];
        for (int i = 1; i <= lower.length; i++) {
          tokens.add(lower.substring(0, i));
        }
        
        await FirebaseFirestore.instance.collection('doctors').doc(userCredential.user!.uid).set({
          'id': userCredential.user!.uid,
          'name': name,
          'email': _emailController.text.trim(),
          'role': 'doctor',
          'specialization': _specialization,
          'clinic': _clinicController.text.trim(),
          'experienceYears': int.tryParse(_experienceController.text.trim()) ?? 0,
          'about': _aboutController.text.trim(),
          'imageUrl': _imageUrlController.text.trim(),
          'consultationFee': double.tryParse(_feesController.text.trim()) ?? 0.0,
          'rating': 5.0,
          'reviewsCount': 0,
          'searchName': tokens,
          'published': true,
          'phoneNumber': '',
          'address': '',
          'qualifications': [],
          'licenseNumber': '',
          'availableDays': [],
          'availableTimes': {},
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Create patient account in patients collection
        await FirebaseFirestore.instance.collection('patients').doc(userCredential.user!.uid).set({
          'id': userCredential.user!.uid,
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': 'patient',
          'phoneNumber': '',
          'address': '',
          'dateOfBirth': null,
          'gender': '',
          'emergencyContact': '',
          'medicalHistory': [],
          'allergies': [],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Navigate based on role
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => _role == 'doctor' ? const DoctorHomeScreen() : HomeScreen()),
      );
    } catch (e) {
      setState(() {
        _error = _getErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'An account already exists with this email';
        case 'invalid-email':
          return 'Please enter a valid email address';
        case 'weak-password':
          return 'Password is too weak';
        default:
          return 'An error occurred during signup';
      }
    }
    return 'An error occurred during signup';
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Account'),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Join Us!',
                    style: Theme.of(context).textTheme.displayMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Create an account to get started',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32),
                  DropdownButtonFormField<String>(
                    value: _role,
                    items: const [
                      DropdownMenuItem(value: 'patient', child: Text('Patient')),
                      DropdownMenuItem(value: 'doctor', child: Text('Doctor')),
                    ],
                    onChanged: (val) {
                      setState(() { _role = val ?? 'patient'; });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Account Type',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  if (_role == 'doctor') ...[
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _specialization,
                      items: _specialties
                          .map((String s) => DropdownMenuItem<String>(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (String? val) {
                        setState(() { _specialization = val ?? _specialization; });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Specialization',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.medical_services_outlined),
                      ),
                    ),
                    SizedBox(height: 16),
                    AppTextField(
                      label: 'Clinic / Hospital Name',
                      controller: _clinicController,
                      prefixIcon: Icon(Icons.local_hospital_outlined),
                      validator: (v) {
                        if (_role == 'doctor' && (v == null || v.isEmpty)) return 'Enter clinic/hospital';
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    AppTextField(
                      label: 'Years of Experience',
                      controller: _experienceController,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icon(Icons.history_toggle_off),
                      validator: (v) {
                        if (_role == 'doctor' && (int.tryParse(v ?? '') == null)) return 'Enter years as number';
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    AppTextField(
                      label: 'Consultation Fee',
                      controller: _feesController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: Icon(Icons.payments_outlined),
                      validator: (v) {
                        if (_role == 'doctor' && (double.tryParse(v ?? '') == null)) return 'Enter fee';
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    AppTextField(
                      label: 'Profile Image URL (optional)',
                      controller: _imageUrlController,
                      keyboardType: TextInputType.url,
                      prefixIcon: Icon(Icons.image_outlined),
                    ),
                    SizedBox(height: 16),
                    AppTextField(
                      label: 'About (short bio)',
                      controller: _aboutController,
                      prefixIcon: Icon(Icons.info_outline),
                      maxLines: 3,
                      validator: (v) {
                        if (_role == 'doctor' && (v == null || v.isEmpty)) return 'Enter a short bio';
                        return null;
                      },
                    ),
                  ],
                  AppTextField(
                    label: 'Full Name',
                    controller: _nameController,
                    validator: _validateName,
                    prefixIcon: Icon(Icons.person_outline),
                    capitalization: TextCapitalization.words,
                  ),
                  SizedBox(height: 16),
                  AppTextField(
                    label: 'Email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  SizedBox(height: 16),
                  AppTextField(
                    label: 'Password',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    validator: _validatePassword,
                    prefixIcon: Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 16),
                  AppTextField(
                    label: 'Confirm Password',
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    validator: _validateConfirmPassword,
                    prefixIcon: Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 24),
                  if (_error != null) ...[
                    Text(
                      _error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                  ],
                  AppButton(
                    text: 'Create Account',
                    onPressed: _signup,
                    isLoading: _isLoading,
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Log in'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
