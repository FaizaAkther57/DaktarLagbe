import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/common_widgets.dart';
import '../models/appointment.dart';
import '../models/doctor.dart';
import 'doctor_list_screen.dart';
import 'doctor_detail_screen.dart';
import 'appointment_history_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    if (user != null) {
      final userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      if (userData.exists) {
        setState(() {
          _userName = userData.data()?['name'] ?? 'User';
        });
      }
    }
  }

  

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App Bar
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello,',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onBackground.withOpacity(0.7),
                          ),
                        ),
                        Text(
                          _userName,
                          style: theme.textTheme.headlineMedium,
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.person_outline),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ProfileScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Quick Actions
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Quick Actions',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    _QuickActionCard(
                      title: 'Find Doctor',
                      icon: Icons.search,
                      color: Colors.blue[700]!,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => DoctorListScreen()),
                        );
                      },
                    ),
                    _QuickActionCard(
                      title: 'Appointments',
                      icon: Icons.calendar_today,
                      color: Colors.green[700]!,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AppointmentHistoryScreen()),
                        );
                      },
                    ),
                    
                  ],
                ),
              ),


              // Top Doctors
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Top Doctors',
                      style: theme.textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => DoctorListScreen()),
                        );
                      },
                      child: Text('View All'),
                    ),
                  ],
                ),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('doctors')
                    .orderBy('rating', descending: true)
                    .limit(3)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: EmptyState(
                        message: 'No doctors available',
                        icon: Icons.medical_services,
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                      final doctor = Doctor.fromMap(data);

                      return Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: AppCard(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DoctorDetailScreen(doctor: doctor),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              Hero(
                                tag: 'doctor-${doctor.id}',
                                child: CircleAvatar(
                                  radius: 30,
                                  backgroundImage: NetworkImage(doctor.imageUrl),
                                  onBackgroundImageError: (e, _) {},
                                  child: doctor.imageUrl.isEmpty ? Icon(Icons.person) : null,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dr. ${doctor.name}',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      doctor.specialization,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.star, color: Colors.amber, size: 16),
                                        SizedBox(width: 4),
                                        Text(
                                          doctor.rating.toStringAsFixed(1),
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: theme.colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  _QuickActionCardState createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  final TextEditingController _doctorController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _doctorController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.title == 'Quick Book') {
      return AlertDialog(
        title: Text('Add Appointment'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _doctorController,
                decoration: InputDecoration(labelText: 'Doctor Name'),
              ),
              TextField(
                controller: _reasonController,
                decoration: InputDecoration(labelText: 'Reason'),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Text(_selectedDate == null ? 'Select Date' : _selectedDate!.toLocal().toString().split(' ')[0]),
                  Spacer(),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                        });
                      }
                    },
                    child: Text('Pick Date'),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_doctorController.text.isNotEmpty && _reasonController.text.isNotEmpty && _selectedDate != null) {
                Navigator.pop(context);
                // Create appointment using the collected data
              }
            },
            child: Text('Add'),
          ),
        ],
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 100,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: widget.color),
              SizedBox(height: 8),
              Text(
                widget.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: widget.color,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
