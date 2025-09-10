import 'package:cloud_firestore/cloud_firestore.dart';

// Sample data for doctors
final List<Map<String, dynamic>> sampleDoctors = [
  {
    'name': 'Dr. John Smith',
    'specialization': 'Cardiologist',
    'imageUrl': 'https://example.com/doctor1.jpg', // Replace with actual image URL
    'description': 'Experienced cardiologist with over 15 years of practice in cardiac care.',
    'rating': 4.8,
    'availability': ['Monday', 'Wednesday', 'Friday'],
    'experienceYears': 15,
    'phoneNumber': '+1234567890',
    'email': 'dr.smith@example.com',
    'price': 150,
    'education': [
      'MD - Cardiology, Harvard Medical School',
      'MBBS - Johns Hopkins University'
    ]
  },
  {
    'name': 'Dr. Sarah Johnson',
    'specialization': 'Pediatrician',
    'imageUrl': 'https://example.com/doctor2.jpg', // Replace with actual image URL
    'description': 'Dedicated pediatrician specializing in newborn and child healthcare.',
    'rating': 4.9,
    'availability': ['Monday', 'Tuesday', 'Thursday'],
    'experienceYears': 10,
    'phoneNumber': '+1234567891',
    'email': 'dr.johnson@example.com',
    'price': 120,
    'education': [
      'MD - Pediatrics, Stanford University',
      'MBBS - Yale University'
    ]
  },
  {
    'name': 'Dr. Michael Chen',
    'specialization': 'Dermatologist',
    'imageUrl': 'https://example.com/doctor3.jpg', // Replace with actual image URL
    'description': 'Expert dermatologist with special interest in skin cancer prevention.',
    'rating': 4.7,
    'availability': ['Tuesday', 'Wednesday', 'Friday'],
    'experienceYears': 12,
    'phoneNumber': '+1234567892',
    'email': 'dr.chen@example.com',
    'price': 140,
    'education': [
      'MD - Dermatology, Columbia University',
      'MBBS - University of California'
    ]
  },
  {
    'name': 'Dr. Emily Brown',
    'specialization': 'Neurologist',
    'imageUrl': 'https://example.com/doctor4.jpg', // Replace with actual image URL
    'description': 'Specialized in treating complex neurological disorders with a patient-centered approach.',
    'rating': 4.8,
    'availability': ['Monday', 'Thursday', 'Friday'],
    'experienceYears': 14,
    'phoneNumber': '+1234567893',
    'email': 'dr.brown@example.com',
    'price': 160,
    'education': [
      'MD - Neurology, Mayo Clinic',
      'MBBS - Duke University'
    ]
  }
];

Future<void> addSampleDoctors() async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  
  for (final doctorData in sampleDoctors) {
    try {
      await firestore.collection('doctors').add(doctorData);
      print('Added doctor: ${doctorData['name']}');
    } catch (e) {
      print('Error adding doctor ${doctorData['name']}: $e');
    }
  }
  
  print('Finished adding sample doctors');
}
