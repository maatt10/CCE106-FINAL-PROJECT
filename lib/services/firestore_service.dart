import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/subscription.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>>
      get _subscriptionCollection {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('subscriptions');
  }

  Future<void> addSubscription(
    Subscription subscription,
  ) async {
    await _subscriptionCollection.add(
      subscription.toMap(),
    );
  }

  Future<void> updateSubscription(
    String documentId,
    Subscription subscription,
  ) async {
    await _subscriptionCollection
        .doc(documentId)
        .update(subscription.toMap());
  }

  Future<void> deleteSubscription(
    String documentId,
  ) async {
    await _subscriptionCollection
        .doc(documentId)
        .delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>
      getSubscriptions() {
    return _subscriptionCollection.snapshots();
  }
}