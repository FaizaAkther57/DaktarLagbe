class Doctor {
  final String id;
  final String name;
  final String specialization;
  final String imageUrl;
  final String description;
  final double rating;
  final List<String> availability;
  final int experienceYears;
  final String phoneNumber;
  final String email;

  Doctor({
    required this.id,
    required this.name,
    required this.specialization,
    required this.imageUrl,
    required this.description,
    required this.rating,
    required this.availability,
    required this.experienceYears,
    required this.phoneNumber,
    required this.email,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'specialization': specialization,
      'imageUrl': imageUrl,
      'description': description,
      'rating': rating,
      'availability': availability,
      'experienceYears': experienceYears,
      'phoneNumber': phoneNumber,
      'email': email,
    };
  }

  factory Doctor.fromMap(Map<String, dynamic> map) {
    return Doctor(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      specialization: map['specialization'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      description: map['description'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      availability: List<String>.from(map['availability'] ?? []),
      experienceYears: map['experienceYears'] ?? 0,
      phoneNumber: map['phoneNumber'] ?? '',
      email: map['email'] ?? '',
    );
  }
}
