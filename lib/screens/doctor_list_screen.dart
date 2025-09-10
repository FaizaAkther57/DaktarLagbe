import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/doctor.dart';
import '../widgets/common_widgets.dart';
import 'doctor_detail_screen.dart';

class DoctorListScreen extends StatefulWidget {
  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedSpecialty = '';
  String _searchQuery = '';
  Timer? _debounce;

  static const List<String> _specialties = <String>[
    'All',
    'Cardiologist',
    'Dermatologist',
    'Pediatrician',
    'Neurologist',
    'Orthopedic',
    'General Physician',
    'Dentist',
    'ENT Specialist',
    'Gynecologist',
  ];

  Query<Map<String, dynamic>> _getQuery() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('doctors');

    if (_selectedSpecialty.isNotEmpty && _selectedSpecialty != 'All') {
      query = query.where('specialization', isEqualTo: _selectedSpecialty);
    }

    if (_searchQuery.isNotEmpty) {
      final String searchLower = _searchQuery.toLowerCase();
      query = query.where('searchName', arrayContains: searchLower);
    }

    return query.orderBy('rating', descending: true);
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = value.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      IconButton(
                        icon: Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: AppTextField(
                          controller: _searchController,
                          label: 'Search doctors',
                          prefixIcon: Icon(Icons.search),
                          onChange: _onSearchChanged,
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                  },
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Select Specialty',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _specialties.map((String specialty) {
                        final bool isSelected = _selectedSpecialty == specialty;
                        return Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(specialty),
                            selected: isSelected,
                            onSelected: (bool selected) {
                              setState(() {
                                _selectedSpecialty = selected ? specialty : '';
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _getQuery().snapshots(),
                builder: (BuildContext context, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
                  if (snapshot.hasError) {
                    return ErrorMessage(
                      message: 'Error loading doctors: ${snapshot.error}',
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return LoadingOverlay(
                      isLoading: true,
                      child: SizedBox.shrink(),
                    );
                  }

                  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = snapshot.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            Icons.search_off_rounded,
                            size: 64,
                            color: theme.colorScheme.secondary,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No doctors found',
                            style: theme.textTheme.titleLarge,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Try adjusting your search or filters',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: docs.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Map<String, dynamic> data = docs[index].data();
                      final Doctor doctor = Doctor.fromMap(<String, dynamic>{
                        ...data,
                        'id': docs[index].id,
                      });
                      return AppCard(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (BuildContext context) => DoctorDetailScreen(doctor: doctor),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Expanded(
                              flex: 3,
                              child: ClipRRect(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                child: CachedNetworkImage(
                                  imageUrl: data['imageUrl'] ?? '',
                                  fit: BoxFit.cover,
                                  placeholder: (BuildContext context, String url) => Container(
                                    color: Theme.of(context).colorScheme.surfaceVariant,
                                    child: Icon(
                                      Icons.person,
                                      size: 48,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  errorWidget: (BuildContext context, String url, dynamic error) => Container(
                                    color: Theme.of(context).colorScheme.surfaceVariant,
                                    child: Icon(
                                      Icons.error_outline,
                                      size: 48,
                                      color: Theme.of(context).colorScheme.error,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      data['name'] ?? 'Unknown',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      data['specialization'] ?? 'Specialist',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Spacer(),
                                    Row(
                                      children: <Widget>[
                                        Icon(
                                          Icons.star_rounded,
                                          size: 20,
                                          color: Colors.amber,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          (() {
                                            final dynamic val = data['rating'];
                                            if (val is num) return val.toStringAsFixed(1);
                                            return '0.0';
                                          })(),
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


