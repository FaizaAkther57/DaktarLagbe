import 'package:flutter/material.dart';

class DoctorSearchBar extends StatelessWidget {
  final TextEditingController searchController;
  final Function(String) onSearch;
  final Function(String) onFilterSpecialty;
  final List<String> specialties;
  final String? selectedSpecialty;

  const DoctorSearchBar({
    Key? key,
    required this.searchController,
    required this.onSearch,
    required this.onFilterSpecialty,
    required this.specialties,
    this.selectedSpecialty,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search doctors by name or specialty',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Colors.blue[900]!),
              ),
              fillColor: Colors.grey[50],
              filled: true,
            ),
            onChanged: onSearch,
          ),
          SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: Text('All'),
                  selected: selectedSpecialty == null,
                  onSelected: (selected) {
                    if (selected) onFilterSpecialty('');
                  },
                  selectedColor: Colors.blue[100],
                ),
                SizedBox(width: 8),
                ...specialties.map((specialty) {
                  return Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(specialty),
                      selected: specialty == selectedSpecialty,
                      onSelected: (selected) {
                        if (selected) onFilterSpecialty(specialty);
                      },
                      selectedColor: Colors.blue[100],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
