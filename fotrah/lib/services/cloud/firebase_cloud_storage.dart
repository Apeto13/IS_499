
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fotrah/services/cloud/cloud_bill.dart';

class FirebaseCloudStorage {
  static final FirebaseCloudStorage _shared = FirebaseCloudStorage._sharedInstance();
  FirebaseCloudStorage._sharedInstance();
  factory FirebaseCloudStorage() => _shared; // This is a singleton

  final bills = FirebaseFirestore.instance.collection('bill');

  Future<void> createNewBill({
    required String userId,
    required double total,
    required Timestamp billDateTime, // This combines date and time
    required String companyId,
    required String categoryId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      await bills.add({
        'userId': userId,
        'total': total,
        'billDateAndTime': billDateTime, 
        'companyId': companyId,
        'categoryId': categoryId,
        'items': items.map((item) => {
          'itemName': item['itemName'],
          'type': item['type'],
          'price': item['price'],
          'quantity': item['quantity'],
        }).toList(),
      });
      print("Bill created successfully.");
    } catch (e) {
      print("Error creating bill: $e");
      throw Exception("Failed to create bill");
    }
  }

Stream<List<CloudBill>> getBills() {
    return bills.snapshots().map((snapshot) => snapshot.docs.map((doc) => CloudBill.fromSnapshot(doc)).toList());
  }
}