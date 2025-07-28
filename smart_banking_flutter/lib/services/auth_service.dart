import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createBooking({
    required String userId,
    required String userName,
    required String userEmail,
    required String branchId,
    required String service,
    required DateTime dateTime,
  }) async {
    await _db.collection('bookings').add({
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'branchId': branchId,
      'service': service,
      'dateTime': Timestamp.fromDate(dateTime),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getUserBookings(String userId) {
    return _db
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('dateTime', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getNearbyBranches() {
    return _db
        .collection('branches')
        .snapshots(); // You can add location filtering later
  }
}
