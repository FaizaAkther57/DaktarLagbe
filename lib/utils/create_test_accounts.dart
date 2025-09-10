import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Creates test accounts for a doctor and a patient.
/// Set deleteAfterCreation=true to immediately delete created users and their docs.
/// If the accounts already exist, they will be signed in to fetch UID and
/// optionally deleted when deleteAfterCreation is true.
Future<void> createTestAccounts({bool deleteAfterCreation = false}) async {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore db = FirebaseFirestore.instance;

  // Define test credentials
  const String doctorEmail = 'test.doctor@example.com';
  const String patientEmail = 'test.patient@example.com';
  const String commonPassword = 'TestPass#123456';

  // Helper to create or sign in an account and return the user
  Future<UserCredential> _createOrSignIn(String email) async {
    try {
      return await auth.createUserWithEmailAndPassword(
        email: email,
        password: commonPassword,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return await auth.signInWithEmailAndPassword(
          email: email,
          password: commonPassword,
        );
      }
      rethrow;
    }
  }

  // Create/sign-in doctor
  final UserCredential doctorCred = await _createOrSignIn(doctorEmail);
  final String doctorUid = doctorCred.user!.uid;

  // Ensure doctor profile doc exists
  final DocumentReference<Map<String, dynamic>> doctorDoc =
      db.collection('doctors').doc(doctorUid);
  final doctorSnapshot = await doctorDoc.get();
  if (!doctorSnapshot.exists) {
    await doctorDoc.set({
      'name': 'Dr. Test User',
      'email': doctorEmail,
      'specialty': 'General Medicine',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Create/sign-in patient
  final UserCredential patientCred = await _createOrSignIn(patientEmail);
  final String patientUid = patientCred.user!.uid;

  // Ensure patient profile doc exists
  final DocumentReference<Map<String, dynamic>> patientDoc =
      db.collection('patients').doc(patientUid);
  final patientSnapshot = await patientDoc.get();
  if (!patientSnapshot.exists) {
    await patientDoc.set({
      'name': 'Patient Test User',
      'email': patientEmail,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  if (deleteAfterCreation) {
    // Delete Firestore docs first, then users
    try {
      await doctorDoc.delete();
    } catch (_) {}
    try {
      await patientDoc.delete();
    } catch (_) {}

    // Deleting users requires being signed in as that user; switch sessions
    // Delete doctor
    try {
      if (auth.currentUser?.uid != doctorUid) {
        await auth.signOut();
        await auth.signInWithEmailAndPassword(
          email: doctorEmail,
          password: commonPassword,
        );
      }
      await auth.currentUser?.delete();
    } catch (_) {}

    // Delete patient
    try {
      await auth.signOut();
      await auth.signInWithEmailAndPassword(
        email: patientEmail,
        password: commonPassword,
      );
      await auth.currentUser?.delete();
    } catch (_) {}

    // Finally sign out
    await auth.signOut();
  } else {
    // Keep user signed in as the last operation's user to avoid side effects
    await auth.signOut();
  }
}
