import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/common_widgets.dart';
import '../theme/app_theme.dart';
import 'doctor_list_screen.dart';

class AppointmentHistoryScreen extends StatefulWidget {
  @override
  _AppointmentHistoryScreenState createState() => _AppointmentHistoryScreenState();
}

class _AppointmentHistoryScreenState extends State<AppointmentHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'all';
  final List<String> _filters = ['all', 'confirmed', 'pending', 'completed', 'cancelled'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Stream<List<Map<String, dynamic>>> _getAppointmentsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('appointments')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
      List<Map<String, dynamic>> appointments = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      // Apply client-side filtering
      if (_selectedFilter != 'all') {
        appointments = appointments.where((appointment) => 
          appointment['status'] == _selectedFilter).toList();
      }

      // Sort by date (most recent first)
      appointments.sort((a, b) {
        final dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime.now();
        return dateB.compareTo(dateA);
      });

      return appointments;
    });
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));
    final appointmentDate = DateTime(date.year, date.month, date.day);

    if (appointmentDate == today) {
      return 'Today';
    } else if (appointmentDate == tomorrow) {
      return 'Tomorrow';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green[700]!;
      case 'cancelled':
        return Colors.red[700]!;
      case 'confirmed':
        return Colors.blue[700]!;
      default:
        return Colors.orange[700]!;
    }
  }

  Widget _buildUpcomingAppointmentsList(AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
    final theme = Theme.of(context);
    
    if (snapshot.hasError) {
      return ErrorMessage(
        message: 'Error loading appointments: ${snapshot.error}',
        onRetry: () => setState(() {}),
      );
    }

    if (snapshot.connectionState == ConnectionState.waiting) {
      return LoadingOverlay(
        isLoading: true,
        child: Container(),
      );
    }

    final now = DateTime.now();
    final upcomingAppointments = (snapshot.data ?? [])
        .where((appointment) {
          final date = DateTime.tryParse(appointment['date'] ?? '') ?? DateTime.now();
          return date.isAfter(now);
        })
        .toList();

    if (upcomingAppointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy_rounded,
              size: 64,
              color: theme.colorScheme.secondary,
            ),
            SizedBox(height: 16),
            Text(
              'No upcoming appointments',
              style: theme.textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            Text(
              'You have no upcoming appointments',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 24),
            AppButton(
              text: 'Book an Appointment',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DoctorListScreen()),
                );
              },
            ),
          ],
        ),
      );
    }

    return _buildAppointmentsList(upcomingAppointments);
  }

  Widget _buildPastAppointmentsList(AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
    final theme = Theme.of(context);
    
    if (snapshot.hasError) {
      return ErrorMessage(
        message: 'Error loading appointments: ${snapshot.error}',
        onRetry: () => setState(() {}),
      );
    }

    if (snapshot.connectionState == ConnectionState.waiting) {
      return LoadingOverlay(
        isLoading: true,
        child: Container(),
      );
    }

    final now = DateTime.now();
    final pastAppointments = (snapshot.data ?? [])
        .where((appointment) {
          final date = DateTime.tryParse(appointment['date'] ?? '') ?? DateTime.now();
          return date.isBefore(now);
        })
        .toList();

    if (pastAppointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy_rounded,
              size: 64,
              color: theme.colorScheme.secondary,
            ),
            SizedBox(height: 16),
            Text(
              'No past appointments',
              style: theme.textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            Text(
              'You have no past appointments',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return _buildAppointmentsList(pastAppointments);
  }

  Widget _buildAppointmentsList(List<Map<String, dynamic>> appointments) {
    final theme = Theme.of(context);
 
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: appointments.length,
      separatorBuilder: (context, index) => SizedBox(height: 16),
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        final date = DateTime.parse(appointment['date'] ?? '');
        final time = appointment['time'] ?? 'Not specified';
        final status = appointment['status'] ?? 'pending';
        final doctorName = appointment['doctorName'] ?? 'Unknown Doctor';
        final specialization = appointment['specialization'] ?? 'Specialist';
        final imageUrl = appointment['doctorImageUrl'];

        // Group header for date changes
        final bool showDateHeader = index == 0 ||
            _formatDate(DateTime.parse(appointments[index - 1]['date'])) != _formatDate(date);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showDateHeader) ...[
              Padding(
                padding: EdgeInsets.only(
                  left: 8,
                  bottom: 12,
                  top: index == 0 ? 0 : 24,
                ),
                child: Text(
                  _formatDate(date),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
            AppCard(
              onTap: () => _showAppointmentDetails(
                context,
                appointment,
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (imageUrl != null)
                              Container(
                                width: 50,
                                height: 50,
                                margin: EdgeInsets.only(right: 16),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: NetworkImage(imageUrl),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            else
                              Container(
                                width: 50,
                                height: 50,
                                margin: EdgeInsets.only(right: 16),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: theme.colorScheme.primary.withOpacity(0.1),
                                ),
                                child: Icon(
                                  Icons.person,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    doctorName,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    specialization,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            _AppointmentInfoChip(
                              icon: Icons.access_time_rounded,
                              label: time,
                            ),
                            SizedBox(width: 12),
                            _AppointmentStatusChip(
                              status: status,
                              color: _getStatusColor(status),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: Icon(
                        Icons.more_vert,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () => _showAppointmentOptions(
                        context,
                        appointment,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          'My Appointments',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.7),
          tabs: [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: _filters.map((filter) {
                return _FilterChip(
                  label: filter.substring(0, 1).toUpperCase() + filter.substring(1),
                  isSelected: _selectedFilter == filter,
                  onSelected: (selected) {
                    setState(() => _selectedFilter = selected ? filter : 'all');
                  },
                );
              }).toList(),
            ),
          ),

          // Appointments List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Upcoming Appointments
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _getAppointmentsStream(),
                  builder: (context, snapshot) => _buildUpcomingAppointmentsList(snapshot),
                ),

                // Past Appointments
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _getAppointmentsStream(),
                  builder: (context, snapshot) => _buildPastAppointmentsList(snapshot),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAppointmentOptions(BuildContext context, Map<String, dynamic> appointment) {
    final theme = Theme.of(context);
    final status = appointment['status'] ?? 'pending';

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status == 'pending') ...[
              ListTile(
                leading: Icon(Icons.edit_calendar, color: theme.colorScheme.primary),
                title: Text('Reschedule Appointment'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    '/reschedule',
                    arguments: appointment,
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.cancel, color: theme.colorScheme.error),
                title: Text('Cancel Appointment'),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Cancel Appointment'),
                      content: Text(
                        'Are you sure you want to cancel this appointment? This action cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('NO, KEEP IT'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            'YES, CANCEL',
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    try {
                      await FirebaseFirestore.instance
                          .collection('appointments')
                          .doc(appointment['id'])
                          .update({'status': 'cancelled'});
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to cancel appointment: $e'),
                            backgroundColor: theme.colorScheme.error,
                          ),
                        );
                      }
                    }
                  }
                },
              ),
            ],
            ListTile(
              leading: Icon(Icons.info_outline, color: theme.colorScheme.primary),
              title: Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _showAppointmentDetails(context, appointment);
              },
            ),
            if (status == 'completed') ListTile(
              leading: Icon(Icons.rate_review, color: theme.colorScheme.primary),
              title: Text('Write a Review'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/write-review',
                  arguments: appointment,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAppointmentDetails(BuildContext context, Map<String, dynamic> appointment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        final status = appointment['status'] ?? 'pending';
        final statusColor = _getStatusColor(status);
        
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Appointment Details',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 32),
                  _DetailItem(
                    icon: Icons.person,
                    title: 'Doctor',
                    value: appointment['doctorName'] ?? 'Unknown Doctor',
                  ),
                  _DetailItem(
                    icon: Icons.calendar_today,
                    title: 'Date',
                    value: _formatDate(DateTime.parse(appointment['date'])),
                  ),
                  _DetailItem(
                    icon: Icons.access_time,
                    title: 'Time',
                    value: appointment['time'] ?? 'Not specified',
                  ),
                  _DetailItem(
                    icon: Icons.local_hospital,
                    title: 'Specialization',
                    value: appointment['specialization'] ?? 'Not specified',
                  ),
                  if (appointment['notes']?.isNotEmpty ?? false) _DetailItem(
                    icon: Icons.note,
                    title: 'Notes',
                    value: appointment['notes'],
                  ),
                  SizedBox(height: 32),
                  if (status == 'pending') ...[
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            text: 'Cancel Appointment',
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Cancel Appointment'),
                                  content: Text(
                                    'Are you sure you want to cancel this appointment? This action cannot be undone.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: Text('NO, KEEP IT'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: Text('YES, CANCEL'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: theme.colorScheme.error,
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                try {
                                  await FirebaseFirestore.instance
                                      .collection('appointments')
                                      .doc(appointment['id'])
                                      .update({'status': 'cancelled'});
                                  Navigator.pop(context);
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to cancel appointment: $e'),
                                      backgroundColor: theme.colorScheme.error,
                                    ),
                                  );
                                }
                              }
                            },
                            isOutlined: true,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: AppButton(
                            text: 'Reschedule',
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/reschedule',
                                arguments: appointment,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Function(bool) onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isSelected 
              ? theme.colorScheme.onPrimary 
              : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        selected: isSelected,
        showCheckmark: false,
        selectedColor: theme.colorScheme.primary,
        backgroundColor: theme.colorScheme.surfaceVariant,
        onSelected: onSelected,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}

class _AppointmentInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _AppointmentInfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentStatusChip extends StatelessWidget {
  final String status;
  final Color color;

  const _AppointmentStatusChip({
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DetailItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onBackground.withOpacity(0.6),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
