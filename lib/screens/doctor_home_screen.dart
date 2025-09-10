import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import 'doctor_profile_edit_screen.dart';
import 'doctor_appointments_screen.dart';
import 'doctor_patients_screen.dart';
import 'doctor_notifications_screen.dart';
import 'login_screen.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({Key? key}) : super(key: key);

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  String _doctorName = '';
  String _specialization = '';
  String _clinic = '';
  double _rating = 0.0;
  int _reviewsCount = 0;
  int _todayAppointments = 0;
  int _pendingAppointments = 0;
  int _totalPatients = 0;

  @override
  void initState() {
    super.initState();
    _loadDoctorData();
  }

  Future<void> _loadDoctorData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Load doctor profile
      final doctorDoc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(user.uid)
          .get();

      if (doctorDoc.exists) {
        final data = doctorDoc.data()!;
        setState(() {
          _doctorName = data['name'] ?? 'Doctor';
          _specialization = data['specialization'] ?? '';
          _clinic = data['clinic'] ?? '';
          _rating = (data['rating'] ?? 0.0).toDouble();
          _reviewsCount = data['reviewsCount'] ?? 0;
        });
      }

      // Load today's appointments (simplified query to avoid index issues)
      final todayAppointments = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: user.uid)
          .get();

      // Load pending appointments
      final pendingAppointments = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      // Load total patients (unique patients who have had appointments)
      final allAppointments = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: user.uid)
          .where('status', whereIn: ['confirmed', 'completed'])
          .get();

      Set<String> uniquePatients = {};
      for (var doc in allAppointments.docs) {
        final appointment = doc.data();
        uniquePatients.add(appointment['userId'] ?? '');
      }

      // Filter today's appointments manually
      final today = DateTime.now();
      final todayCount = todayAppointments.docs.where((doc) {
        final appointmentDate = doc.data()['date'];
        if (appointmentDate is Timestamp) {
          final date = appointmentDate.toDate();
          return date.year == today.year && 
                 date.month == today.month && 
                 date.day == today.day;
        }
        return false;
      }).length;

      setState(() {
        _todayAppointments = todayCount;
        _pendingAppointments = pendingAppointments.docs.length;
        _totalPatients = uniquePatients.length;
      });
    } catch (e) {
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    }
  }

  Future<void> _showLogoutDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Sign Out'),
              onPressed: () {
                Navigator.of(context).pop();
                _signOut();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, Dr. $_doctorName'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DoctorNotificationsScreen(),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DoctorProfileEditScreen(),
                    ),
                  );
                  break;
                case 'logout':
                  _showLogoutDialog();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: AppTheme.primaryColor),
                    SizedBox(width: 8),
                    Text('Edit Profile'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Sign Out'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Stats
            _buildStatsRow(),
            const SizedBox(height: 24),

            // Profile Summary
            _buildProfileSummary(),
            const SizedBox(height: 24),

            // Quick Actions
            _buildSectionTitle('Quick Actions'),
            const SizedBox(height: 16),
            _buildQuickActions(),
            const SizedBox(height: 24),

            // Today's Appointments Preview
            _buildSectionTitle('Today\'s Appointments'),
            const SizedBox(height: 16),
            _buildTodaysAppointments(),
            const SizedBox(height: 24),

            // Recent Patients
            _buildSectionTitle('Recent Patients'),
            const SizedBox(height: 16),
            _buildRecentPatients(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Today\'s Appointments',
            _todayAppointments.toString(),
            Icons.event,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Pending Requests',
            _pendingAppointments.toString(),
            Icons.pending_actions,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Total Patients',
            _totalPatients.toString(),
            Icons.people,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildActionCard(
          'Edit Profile',
          Icons.edit,
          Colors.blue,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DoctorProfileEditScreen(),
              ),
            );
          },
        ),
        _buildActionCard(
          'My Appointments',
          Icons.event,
          Colors.green,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DoctorAppointmentsScreen(),
              ),
            );
          },
        ),
        _buildActionCard(
          'My Patients',
          Icons.people,
          Colors.purple,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DoctorPatientsScreen(),
              ),
            );
          },
        ),
        _buildActionCard(
          'Notifications',
          Icons.notifications,
          Colors.orange,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DoctorNotificationsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodaysAppointments() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.event_available, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No appointments today',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Filter today's appointments
        final today = DateTime.now();
        final todayAppointments = snapshot.data!.docs.where((doc) {
          final appointmentData = doc.data() as Map<String, dynamic>;
          final appointmentDate = appointmentData['date'];
          if (appointmentDate is Timestamp) {
            final date = appointmentDate.toDate();
            return date.year == today.year && 
                   date.month == today.month && 
                   date.day == today.day;
          }
          return false;
        }).toList();

        return Column(
          children: todayAppointments.take(3).map((doc) {
            final appointment = doc.data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    (appointment['patientName'] ?? 'P')[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(appointment['patientName'] ?? 'Unknown'),
                subtitle: Text(appointment['reason'] ?? 'No reason provided'),
                trailing: Text(
                  _formatTime(DateTime.tryParse(appointment['date'] ?? '') ?? DateTime.now()),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildRecentPatients() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No patients yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Get unique patients with confirmed/completed status
        Set<String> seenPatients = {};
        List<DocumentSnapshot> uniquePatients = [];

        for (var doc in snapshot.data!.docs) {
          final appointment = doc.data() as Map<String, dynamic>;
          final status = appointment['status'] ?? '';
          final patientName = appointment['patientName'] ?? '';
          
          if ((status == 'confirmed' || status == 'completed') && 
              !seenPatients.contains(patientName)) {
            seenPatients.add(patientName);
            uniquePatients.add(doc);
          }
        }

        // Sort by date (most recent first)
        uniquePatients.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          final dateA = dataA['date'];
          final dateB = dataB['date'];
          if (dateA is Timestamp && dateB is Timestamp) {
            return dateB.compareTo(dateA);
          }
          return 0;
        });

        return Column(
          children: uniquePatients.take(3).map((doc) {
            final appointment = doc.data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    (appointment['patientName'] ?? 'P')[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(appointment['patientName'] ?? 'Unknown'),
                subtitle: Text('Last visit: ${_formatDate(DateTime.tryParse(appointment['date'] ?? '') ?? DateTime.now())}'),
                trailing: _buildStatusChip(appointment['status'] ?? ''),
              ),
            );
          }).toList(),
        );
      },
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

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  Widget _buildProfileSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    _doctorName.isNotEmpty ? _doctorName[0].toUpperCase() : 'D',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _doctorName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_specialization.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _specialization,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      if (_clinic.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          _clinic,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          _rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$_reviewsCount reviews',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DoctorProfileEditScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit Profile'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: BorderSide(color: AppTheme.primaryColor),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showLogoutDialog,
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Sign Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}