import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/appointment.dart';
import '../theme/app_theme.dart';

class DoctorNotificationsScreen extends StatefulWidget {
  const DoctorNotificationsScreen({Key? key}) : super(key: key);

  @override
  State<DoctorNotificationsScreen> createState() => _DoctorNotificationsScreenState();
}

class _DoctorNotificationsScreenState extends State<DoctorNotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            onPressed: _markAllAsRead,
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'ll receive notifications for new appointments and cancellations',
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              return _buildNotificationCard(notifications[index]);
            },
          );
        },
      ),
    );
  }

  Stream<List<Map<String, dynamic>>> _getNotificationsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
      List<Map<String, dynamic>> notifications = [];

      for (var doc in snapshot.docs) {
        final appointment = Appointment.fromMap(doc.data(), doc.id);
        final now = DateTime.now();
        final appointmentTime = appointment.date;
        
        // Only show recent notifications (last 7 days)
        if (now.difference(appointmentTime).inDays <= 7) {
          String notificationType = '';
          String message = '';
          IconData icon = Icons.info;
          Color color = Colors.blue;

          switch (appointment.status) {
            case 'pending':
              notificationType = 'New Appointment Request';
              message = '${appointment.patientName} requested an appointment for ${_formatDateTime(appointment.date)}';
              icon = Icons.event_available;
              color = Colors.orange;
              break;
            case 'cancelled':
              notificationType = 'Appointment Cancelled';
              message = '${appointment.patientName} cancelled their appointment for ${_formatDateTime(appointment.date)}';
              icon = Icons.event_busy;
              color = Colors.red;
              break;
            case 'confirmed':
              notificationType = 'Appointment Confirmed';
              message = 'Appointment with ${appointment.patientName} confirmed for ${_formatDateTime(appointment.date)}';
              icon = Icons.check_circle;
              color = Colors.green;
              break;
            case 'completed':
              notificationType = 'Appointment Completed';
              message = 'Appointment with ${appointment.patientName} completed on ${_formatDateTime(appointment.date)}';
              icon = Icons.done_all;
              color = Colors.blue;
              break;
          }

          notifications.add({
            'id': appointment.id,
            'type': notificationType,
            'message': message,
            'icon': icon,
            'color': color,
            'time': appointmentTime,
            'status': appointment.status,
            'patientName': appointment.patientName,
            'appointment': appointment,
          });
        }
      }

      // Sort by date (most recent first) - client-side sorting
      notifications.sort((a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime));

      return notifications;
    });
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final type = notification['type'] as String;
    final message = notification['message'] as String;
    final icon = notification['icon'] as IconData;
    final color = notification['color'] as Color;
    final time = notification['time'] as DateTime;
    final status = notification['status'] as String;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(
            icon,
            color: color,
          ),
        ),
        title: Text(
          type,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              message,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(time),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: status == 'pending' 
            ? _buildActionButtons(notification['appointment'] as Appointment)
            : null,
        isThreeLine: true,
      ),
    );
  }

  Widget _buildActionButtons(Appointment appointment) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.check, color: Colors.green),
          onPressed: () => _updateAppointmentStatus(appointment.id, 'confirmed'),
          tooltip: 'Accept',
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: () => _showCancelDialog(appointment.id, appointment.patientName),
          tooltip: 'Decline',
        ),
      ],
    );
  }

  Future<void> _updateAppointmentStatus(String appointmentId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment $status successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating appointment: $e')),
      );
    }
  }

  Future<void> _showCancelDialog(String appointmentId, String patientName) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Decline Appointment'),
          content: Text('Are you sure you want to decline the appointment with $patientName?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Decline'),
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

  Future<void> _markAllAsRead() async {
    // In a real app, you might want to mark notifications as read in a separate collection
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read')),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at $displayHour:$minute $period';
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notificationDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (notificationDate == today) {
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return 'Today at $displayHour:$minute $period';
    } else if (notificationDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

