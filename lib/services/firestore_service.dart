import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/renewal_utils.dart';

import '../models/subscription.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _subscriptionCollection {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('subscriptions');
  }

  Future<void> addSubscription(Subscription subscription) async {
    await _subscriptionCollection.add(subscription.toMap());
  }

  Future<void> updateSubscription(
    String documentId,
    Subscription subscription,
  ) async {
    await _subscriptionCollection.doc(documentId).update(subscription.toMap());
  }

  Future<void> deleteSubscription(String documentId) async {
    await _subscriptionCollection.doc(documentId).delete();
  }

  Future<void> updateStatus(String documentId, String status) async {
    await _subscriptionCollection.doc(documentId).update({'status': status});
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getSubscriptions() {
    return _subscriptionCollection.snapshots();
  }

  Future<int> advanceOverdueRenewals() async {
    final snapshot = await _subscriptionCollection.get();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final batch = _firestore.batch();
    int updated = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final status = data['status'] ?? 'active';
      if (status != 'active') continue;

      final renewalStr = data['renewalDate'];
      if (renewalStr == null) continue;

      DateTime renewal;
      try {
        renewal = DateTime.parse(renewalStr);
      } catch (_) {
        continue;
      }

      final renewalDay = DateTime(renewal.year, renewal.month, renewal.day);

      // Not overdue → skip.
      if (!renewalDay.isBefore(today)) continue;

      final cycle = data['billingCycle'] as String? ?? 'Monthly';
      final next = nextRenewalAfter(
        currentRenewal: renewal,
        asOf: today,
        billingCycle: cycle,
      );

      batch.update(doc.reference, {'renewalDate': next.toIso8601String()});
      updated++;
    }

    if (updated > 0) {
      await batch.commit();
    }

    return updated;
  }
}
