import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserSettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DocumentReference<Map<String, dynamic>> get _userDocument {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    return _firestore.collection('users').doc(user.uid);
  }

  Future<String> getPreferredCurrency() async {
    final snapshot = await _userDocument.get();

    final data = snapshot.data();

    if (data == null || data['preferredCurrency'] == null) {
      return 'PHP';
    }

    return data['preferredCurrency'] as String;
  }

  Future<void> setPreferredCurrency(String currency) async {
    await _userDocument.set({
      'preferredCurrency': currency,
    }, SetOptions(merge: true));
  }

  Stream<String> preferredCurrencyStream() {
    return _userDocument.snapshots().map((snapshot) {
      final data = snapshot.data();

      if (data == null || data['preferredCurrency'] == null) {
        return 'PHP';
      }

      return data['preferredCurrency'] as String;
    });
  }

  // ===== Reminder settings =====

  Future<Map<String, dynamic>> getReminderSettings() async {
    final snapshot = await _userDocument.get();
    final data = snapshot.data() ?? {};

    return {
      'remindersEnabled': data['remindersEnabled'] as bool? ?? false,
      'leadTimeDays': data['leadTimeDays'] as int? ?? 3,
      'reminderHour': data['reminderHour'] as int? ?? 9,
      'reminderMinute': data['reminderMinute'] as int? ?? 0,
    };
  }

  Future<void> setReminderSettings({
    required bool enabled,
    required int leadTimeDays,
    required int hour,
    required int minute,
  }) async {
    await _userDocument.set({
      'remindersEnabled': enabled,
      'leadTimeDays': leadTimeDays,
      'reminderHour': hour,
      'reminderMinute': minute,
    }, SetOptions(merge: true));
  }

  Stream<Map<String, dynamic>> reminderSettingsStream() {
    return _userDocument.snapshots().map((snapshot) {
      final data = snapshot.data() ?? {};
      return {
        'remindersEnabled': data['remindersEnabled'] as bool? ?? false,
        'leadTimeDays': data['leadTimeDays'] as int? ?? 3,
        'reminderHour': data['reminderHour'] as int? ?? 9,
        'reminderMinute': data['reminderMinute'] as int? ?? 0,
      };
    });
  }
}
