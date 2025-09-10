import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/appointment.dart';
import '../theme/app_theme.dart';

class DoctorPatientsScreen extends StatefulWidget {
  const DoctorPatientsScreen({Key? key}) : super(key: key);

  @override
  State<DoctorPatientsScreen> createState() => _DoctorPatientsScreenState();
}

class _DoctorPatientsScreenState extends State<DoctorPatientsScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<List<Map<String, dynamic>>> _getPatientsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
      // Group appointments by patient
      Map<String, Map<String, dynamic>> patientsMap = {};
      
      for (var doc in snapshot.docs) {
        final appointment = Appointment.fromMap(doc.data(), doc.id);
        
        // Filter for confirmed and completed appointments only
        if (appointment.status != 'confirmed' && appointment.status != 'completed') {
          continue;
        }
        
        final patientId = appointment.userId;
        
        if (patientsMap.containsKey(patientId)) {
          patientsMap[patientId]!['appointments'].add(appointment);
          // Update last visit if this appointment is more recent
          if (appointment.date.isAfter(patientsMap[patientId]!['lastVisit'])) {
            patientsMap[patientId]!['lastVisit'] = appointment.date;
          }
          patientsMap[patientId]!['totalVisits']++;
        } else {
          patientsMap[patientId] = {
            'patientId': patientId,
            'patientName': appointment.patientName,
            'appointments': [appointment],
            'lastVisit': appointment.date,
            'totalVisits': 1,
          };
        }
      }

      // Convert to list and sort by last visit
      List<Map<String, dynamic>> patients = patientsMap.values.toList();
      patients.sort((a, b) => (b['lastVisit'] as DateTime).compareTo(a['lastVisit'] as DateTime));
      
      // Update total visits count
      for (var patient in patients) {
        patient['totalVisits'] = (patient['appointments'] as List).length;
      }

      return patients;
    });
  }

  Widget _buildPatientCard(Map<String, dynamic> patientData) {
    final patientName = patientData['patientName'] as String;
    final lastVisit = patientData['lastVisit'] as DateTime;
    final totalVisits = patientData['totalVisits'] as int;
    final appointments = patientData['appointments'] as List<Appointment>;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor,
          child: Text(
            patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          patientName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Visits: $totalVisits'),
            Text('Last Visit: ${_formatDate(lastVisit)}'),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Appointment History',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                ...appointments.map((appointment) => _buildAppointmentHistoryItem(appointment)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentHistoryItem(Appointment appointment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.reason,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(appointment.date),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _buildStatusChip(appointment.status),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'confirmed':
        color = Colors.green;
        break;
      case 'completed':
        color = Colors.blue;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final appointmentDate = DateTime(date.year, date.month, date.day);

    if (appointmentDate == today) {
      return 'Today';
    } else if (appointmentDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at $displayHour:$minute $period';
  }

  List<Map<String, dynamic>> _filterPatients(List<Map<String, dynamic>> patients) {
    if (_searchQuery.isEmpty) return patients;
    
    return patients.where((patient) {
      final name = (patient['patientName'] as String).toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Patients'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search patients...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Patients List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _getPatientsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final allPatients = snapshot.data ?? [];
                final filteredPatients = _filterPatients(allPatients);

                if (filteredPatients.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty ? 'No patients found' : 'No patients yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Try a different search term'
                              : 'Your patients will appear here after appointments',
                          style: TextStyle(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredPatients.length,
                  itemBuilder: (context, index) {
                    return _buildPatientCard(filteredPatients[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

