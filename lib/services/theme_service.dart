import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ThemeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DocumentReference<Map<String, dynamic>> get _userDocument {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User is not logged in.');
    }
    return _firestore.collection('users').doc(user.uid);
  }

  Future<bool> getDarkMode() async {
    try {
      final snapshot = await _userDocument.get();
      final data = snapshot.data();
      if (data == null) return false;
      return data['darkMode'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> setDarkMode(bool enabled) async {
    await _userDocument.set(
      {'darkMode': enabled},
      SetOptions(merge: true),
    );
  }

  Stream<bool> darkModeStream() {
    return _userDocument.snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return false;
      return data['darkMode'] as bool? ?? false;
    });
  }
}