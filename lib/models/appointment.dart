class Appointment {
  final String id;
  final String doctorName;
  final String doctorId;
  final String userId;
  final String patientName;
  final DateTime date;
  final String reason;
  final String time;
  final String status;

  Appointment({
    required this.id,
    required this.doctorName,
    required this.doctorId,
    required this.userId,
    required this.patientName,
    required this.date,
    required this.reason,
    this.time = '',
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'doctorName': doctorName,
      'doctorId': doctorId,
      'userId': userId,
      'patientName': patientName,
      'date': date.toIso8601String(),
      'reason': reason,
      'time': time,
      'status': status,
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map, String id) {
    return Appointment(
      id: id,
      doctorName: map['doctorName'] ?? '',
      doctorId: map['doctorId'] ?? '',
      userId: map['userId'] ?? '',
      patientName: map['patientName'] ?? '',
      date: map['date'] is DateTime ? map['date'] : DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      reason: map['reason'] ?? '',
      time: map['time'] ?? '',
      status: map['status'] ?? 'pending',
    );
  }
}
