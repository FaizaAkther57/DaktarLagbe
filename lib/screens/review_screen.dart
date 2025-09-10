import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/doctor.dart';
import '../models/review.dart';

class ReviewScreen extends StatefulWidget {
  final Doctor doctor;

  const ReviewScreen({Key? key, required this.doctor}) : super(key: key);

  @override
  _ReviewScreenState createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final _commentController = TextEditingController();
  double _rating = 5.0;
  bool _isSubmitting = false;

  Future<void> _submitReview() async {
    if (_commentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please write a comment')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Get user name from profile
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      final userName = userDoc.data()?['name'] ?? user.email ?? 'Anonymous';

      // Create review
      final reviewData = Review(
        id: '',
        doctorId: widget.doctor.id,
        userId: user.uid,
        userName: userName,
        rating: _rating,
        comment: _commentController.text,
        createdAt: DateTime.now(),
      ).toMap();

      // Add review to Firestore
      await FirebaseFirestore.instance
          .collection('reviews')
          .add(reviewData);

      // Update doctor's rating
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('doctorId', isEqualTo: widget.doctor.id)
          .get();

      double totalRating = 0;
      for (var doc in reviewsSnapshot.docs) {
        totalRating += (doc.data()['rating'] ?? 0.0);
      }
      
      final newRating = totalRating / reviewsSnapshot.docs.length;
      
      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(widget.doctor.id)
          .update({'rating': newRating});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Review submitted successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting review: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Write a Review'),
        backgroundColor: Colors.blue[900],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: Hero(
                tag: 'doctor-${widget.doctor.id}',
                child: CircleAvatar(
                  backgroundImage: NetworkImage(widget.doctor.imageUrl),
                  onBackgroundImageError: (e, _) {},
                  child: widget.doctor.imageUrl.isEmpty ? Icon(Icons.person) : null,
                ),
              ),
              title: Text(widget.doctor.name),
              subtitle: Text(widget.doctor.specialization),
            ),
            SizedBox(height: 24),
            Text(
              'Rate your experience',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    size: 32,
                    color: Colors.amber,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1.0;
                    });
                  },
                );
              }),
            ),
            SizedBox(height: 24),
            Text(
              'Write your review',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _commentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Share your experience with Dr. ${widget.doctor.name}',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: _isSubmitting
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Submit Review',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
