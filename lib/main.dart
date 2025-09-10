

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/doctor_home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'theme/app_theme.dart';
import 'utils/seed.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyDyIKuRDHTG4f0icQlKnT6E862coCyL2dY",
        appId: "1:322698909833:android:b9824f18916db180eece58", // Using Android app ID temporarily
        messagingSenderId: "322698909833",
        projectId: "healthapp-1476a",
        storageBucket: "healthapp-1476a.firebasestorage.app",
        authDomain: "healthapp-1476a.firebaseapp.com",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  // Uncomment to seed demo doctors once, then comment again
  // await seedDoctors();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dr Appointment',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            final String uid = snapshot.data!.uid;
            
            // Check both doctors and patients collections to determine user type
            return FutureBuilder<List<DocumentSnapshot<Map<String, dynamic>>>>(
              future: Future.wait([
                FirebaseFirestore.instance.collection('doctors').doc(uid).get(),
                FirebaseFirestore.instance.collection('patients').doc(uid).get(),
              ]),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final doctorDoc = snap.data?[0];
                final patientDoc = snap.data?[1];

                // If user exists in doctors collection, they are a doctor
                if (doctorDoc?.exists ?? false) {
                  return const DoctorHomeScreen();
                }
                
                // If user exists in patients collection, they are a patient
                if (patientDoc?.exists ?? false) {
                  return HomeScreen();
                }

                // If user doesn't exist in either collection, show login screen
                return LoginScreen();
              },
            );
          }
          return LoginScreen();
        },
      ),
    );
  }
}
// ...existing code...
