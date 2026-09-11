import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveScanResult({
    required String userId,
    required String disease,
    required double confidence,
  }) async {
    await _firestore.collection('scans').add({
      'userId': userId,
      'disease': disease,
      'confidence': confidence,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}