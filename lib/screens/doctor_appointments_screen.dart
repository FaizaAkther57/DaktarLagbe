import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/appointment.dart';
import '../theme/app_theme.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({Key? key}) : super(key: key);

  @override
  State<DoctorAppointmentsScreen> createState() => _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'Today';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Test function to create a test appointment
  Future<void> _createTestAppointment() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      final testAppointment = {
        'doctorId': user.uid,
        'doctorName': 'Test Doctor',
        'date': DateTime.now().add(Duration(hours: 1)).toIso8601String(),
        'time': '10:00 AM',
        'status': 'pending',
        'userId': 'test-patient-id',
        'patientName': 'Test Patient',
        'reason': 'Test appointment',
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      final docRef = await FirebaseFirestore.instance.collection('appointments').add(testAppointment);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Test appointment created!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating test appointment: $e')),
        );
      }
    }
  }

  Future<void> _updateAppointmentStatus(String appointmentId, String status) async {
    if (!mounted) return;
    
    try {
      // First, let's check if the document exists
      final docRef = FirebaseFirestore.instance.collection('appointments').doc(appointmentId);
      final docSnapshot = await docRef.get();
      
      if (!docSnapshot.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Appointment not found!')),
          );
        }
        return;
      }
      
      await docRef.update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Appointment $status successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating appointment: $e')),
        );
      }
    }
  }

  Future<void> _showCancelDialog(String appointmentId, String patientName) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Appointment'),
          content: Text('Are you sure you want to cancel the appointment with $patientName?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Yes, Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                _updateAppointmentStatus(appointmentId, 'cancelled');
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    if (!mounted) return const SizedBox.shrink();
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    appointment.patientName.isNotEmpty
                        ? appointment.patientName[0].toUpperCase()
                        : 'P',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.patientName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        appointment.reason,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(appointment.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _formatDateTime(appointment.date),
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const Spacer(),
                if (appointment.status == 'pending') ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: mounted ? () {
                        _updateAppointmentStatus(appointment.id, 'confirmed');
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: mounted ? () {
                        _showCancelDialog(appointment.id, appointment.patientName);
                      } : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'confirmed':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      case 'completed':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color,
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final appointmentDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (appointmentDate == today) {
      return 'Today at ${_formatTime(dateTime)}';
    } else if (appointmentDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow at ${_formatTime(dateTime)}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${_formatTime(dateTime)}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  Stream<List<Appointment>> _getAppointmentsStream(String filter) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    // Use simple query without compound filters to avoid index requirements
    return FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
      List<Appointment> appointments = snapshot.docs.map((doc) {
        return Appointment.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      // Apply client-side filtering
      switch (filter) {
        case 'Today':
          final today = DateTime.now();
          appointments = appointments.where((appointment) {
            final appointmentDate = appointment.date;
            return appointmentDate.year == today.year && 
                   appointmentDate.month == today.month && 
                   appointmentDate.day == today.day;
          }).toList();
          break;
        case 'Pending':
          appointments = appointments.where((appointment) => 
            appointment.status == 'pending').toList();
          break;
        case 'All':
          // No additional filtering
          break;
      }

      // Sort by date
      appointments.sort((a, b) => a.date.compareTo(b.date));
      return appointments;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Pending'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: TabBarView(
        key: const ValueKey('appointments_tab_view'),
        controller: _tabController,
        children: [
          _buildAppointmentsList('Today'),
          _buildAppointmentsList('Pending'),
          _buildAppointmentsList('All'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createTestAppointment,
        child: Icon(Icons.add),
        tooltip: 'Create Test Appointment',
      ),
    );
  }

  Widget _buildAppointmentsList(String filter) {
    return KeyedSubtree(
      key: ValueKey('appointments_list_$filter'),
      child: StreamBuilder<List<Appointment>>(
      stream: _getAppointmentsStream(filter),
      builder: (context, snapshot) {
        if (!mounted) {
          return const SizedBox.shrink();
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  'Error loading appointments',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final appointments = snapshot.data ?? [];

        if (appointments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_busy,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${filter.toLowerCase()} appointments found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  filter == 'Pending' 
                    ? 'New appointment requests will appear here'
                    : 'Your appointments will appear here',
                  style: TextStyle(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            if (!mounted) return const SizedBox.shrink();
            return _buildAppointmentCard(appointments[index]);
          },
        );
      },
    ),
    );
  }
}

