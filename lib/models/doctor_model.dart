class DoctorModel {
  final String id;
  final String name;
  final String email;
  final String specialization;
  final String clinic;
  final int experienceYears;
  final String about;
  final String imageUrl;
  final double consultationFee;
  final double rating;
  final int reviewsCount;
  final bool published;
  final List<String> searchName;
  final DateTime? createdAt;
  
  // Doctor-specific fields
  final List<String> availableDays; // ['Monday', 'Tuesday', etc.]
  final Map<String, List<String>> availableTimes; // {'Monday': ['09:00', '10:00'], ...}
  final String phoneNumber;
  final String address;
  final List<String> qualifications;
  final String licenseNumber;

  DoctorModel({
    required this.id,
    required this.name,
    required this.email,
    required this.specialization,
    required this.clinic,
    required this.experienceYears,
    required this.about,
    required this.imageUrl,
    required this.consultationFee,
    required this.rating,
    required this.reviewsCount,
    required this.published,
    required this.searchName,
    this.createdAt,
    this.availableDays = const [],
    this.availableTimes = const {},
    this.phoneNumber = '',
    this.address = '',
    this.qualifications = const [],
    this.licenseNumber = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'specialization': specialization,
      'clinic': clinic,
      'experienceYears': experienceYears,
      'about': about,
      'imageUrl': imageUrl,
      'consultationFee': consultationFee,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'published': published,
      'searchName': searchName,
      'createdAt': createdAt?.toIso8601String(),
      'availableDays': availableDays,
      'availableTimes': availableTimes,
      'phoneNumber': phoneNumber,
      'address': address,
      'qualifications': qualifications,
      'licenseNumber': licenseNumber,
    };
  }

  factory DoctorModel.fromMap(Map<String, dynamic> map, String id) {
    return DoctorModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      specialization: map['specialization'] ?? '',
      clinic: map['clinic'] ?? '',
      experienceYears: map['experienceYears']?.toInt() ?? 0,
      about: map['about'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      consultationFee: (map['consultationFee'] ?? 0.0).toDouble(),
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewsCount: map['reviewsCount']?.toInt() ?? 0,
      published: map['published'] ?? false,
      searchName: List<String>.from(map['searchName'] ?? []),
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      availableDays: List<String>.from(map['availableDays'] ?? []),
      availableTimes: Map<String, List<String>>.from(map['availableTimes'] ?? {}),
      phoneNumber: map['phoneNumber'] ?? '',
      address: map['address'] ?? '',
      qualifications: List<String>.from(map['qualifications'] ?? []),
      licenseNumber: map['licenseNumber'] ?? '',
    );
  }

  DoctorModel copyWith({
    String? id,
    String? name,
    String? email,
    String? specialization,
    String? clinic,
    int? experienceYears,
    String? about,
    String? imageUrl,
    double? consultationFee,
    double? rating,
    int? reviewsCount,
    bool? published,
    List<String>? searchName,
    DateTime? createdAt,
    List<String>? availableDays,
    Map<String, List<String>>? availableTimes,
    String? phoneNumber,
    String? address,
    List<String>? qualifications,
    String? licenseNumber,
  }) {
    return DoctorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      specialization: specialization ?? this.specialization,
      clinic: clinic ?? this.clinic,
      experienceYears: experienceYears ?? this.experienceYears,
      about: about ?? this.about,
      imageUrl: imageUrl ?? this.imageUrl,
      consultationFee: consultationFee ?? this.consultationFee,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      published: published ?? this.published,
      searchName: searchName ?? this.searchName,
      createdAt: createdAt ?? this.createdAt,
      availableDays: availableDays ?? this.availableDays,
      availableTimes: availableTimes ?? this.availableTimes,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      qualifications: qualifications ?? this.qualifications,
      licenseNumber: licenseNumber ?? this.licenseNumber,
    );
  }
}


