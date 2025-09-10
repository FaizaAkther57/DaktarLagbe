import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/common_widgets.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'doctor_home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _error;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _selectedRole = 'patient';

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final uid = credential.user!.uid;
      
      if (!mounted) return;
      
      // Check if user exists in doctors or patients collection
      final doctorDoc = await FirebaseFirestore.instance.collection('doctors').doc(uid).get();
      final patientDoc = await FirebaseFirestore.instance.collection('patients').doc(uid).get();
      
      final isDoctorInDatabase = doctorDoc.exists;
      final isPatientInDatabase = patientDoc.exists;
      
      if (!mounted) return;
      
      // Validate role selection matches database
      if (_selectedRole == 'doctor' && !isDoctorInDatabase) {
        if (!mounted) return;
        setState(() {
          _error = 'This email is not registered as a doctor. Please select Patient or sign up as a doctor.';
          _isLoading = false;
        });
        return;
      } else if (_selectedRole == 'patient' && !isPatientInDatabase) {
        if (!mounted) return;
        setState(() {
          _error = 'This email is not registered as a patient. Please select Doctor or sign up as a patient.';
          _isLoading = false;
        });
        return;
      }
      
      // Navigate based on role
      if (_selectedRole == 'doctor' && isDoctorInDatabase) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DoctorHomeScreen()),
        );
      } else if (_selectedRole == 'patient' && isPatientInDatabase) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _getErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email';
        case 'wrong-password':
          return 'Wrong password provided';
        case 'invalid-email':
          return 'Invalid email address';
        case 'user-disabled':
          return 'This account has been disabled';
        case 'invalid-credential':
          return 'Invalid email or password';
        case 'too-many-requests':
          return 'Too many failed attempts. Please try again later';
        case 'network-request-failed':
          return 'Network error. Please check your connection';
        default:
          return 'Authentication error: ${error.message}';
      }
    }
    return 'An error occurred. Please try again';
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
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  SizedBox(height: 40),
                  Text(
                    'Welcome Back!',
                    style: Theme.of(context).textTheme.displayMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Log in to book your next appointment',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Login as:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  ToggleButtons(
                    isSelected: <bool>[_selectedRole == 'patient', _selectedRole == 'doctor'],
                    onPressed: (int index) {
                      setState(() {
                        _selectedRole = index == 0 ? 'patient' : 'doctor';
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    selectedColor: Theme.of(context).colorScheme.onPrimary,
                    fillColor: Theme.of(context).colorScheme.primary,
                    children: const <Widget>[
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text('Patient'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text('Doctor'),
                      ),
                    ],
                  ),
                  SizedBox(height: 36),
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
                  SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // TODO: Implement forgot password
                      },
                      child: Text('Forgot Password?'),
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
                    text: 'Login',
                    onPressed: _login,
                    isLoading: _isLoading,
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => SignupScreen()),
                          );
                        },
                        child: Text('Sign up'),
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
}
