import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fotrah/services/cloud/cloud_bill.dart';
import 'package:fotrah/services/cloud/cloud_storage_exceptions.dart';

class FirebaseCloudStorage {
  static final FirebaseCloudStorage _shared =
      FirebaseCloudStorage._sharedInstance();
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
        'items': items
            .map((item) => {
                  'itemName': item['itemName'],
                  'type': item['type'],
                  'price': item['price'],
                  'quantity': item['quantity'],
                })
            .toList(),
      });
      print("Bill created successfully.");
    } catch (e) {
      print("Error creating bill: $e");
      throw CouldNotCreateBillException;
    }
  }

  Stream<Iterable<CloudBill>> getBills({required String id}) {
    return bills.snapshots().map((event) => event.docs
        .map((doc) => CloudBill.fromSnapshot(doc))
        .where((bill) => bill.id == id));
  }

  Future<Iterable<CloudBill>> getBillsForUser({required String userId}) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('bills')
          .where('userId', isEqualTo: userId) // Filter by the specific user ID
          .get();

      // Map over the querySnapshot's documents, converting each to a CloudBill using fromSnapshot
      Iterable<CloudBill> AllBills =
          querySnapshot.docs.map((doc) => CloudBill.fromSnapshot(doc));

      return AllBills;
    } catch (e) {
      print('Error getting bills for user: $e');
      throw Exception('Failed to get bills');
    }
  }

  Future<void> updateBill({
    required String billId,
    double? total,
    Timestamp? billDateTime,
    List<Map<String, dynamic>>? items,
  }) async {
    try {
      // Reference to the bill document
      final billDocRef =
          FirebaseFirestore.instance.collection('bills').doc(billId);

      // Prepare the update data
      Map<String, Object?> updates = {};
      if (total != null) updates['total'] = total;
      if (billDateTime != null) updates['billDateAndTime'] = billDateTime;
      if (items != null)
        updates['items'] = items
            .map((item) => {
                  'itemName': item['itemName'],
                  'type': item['type'],
                  'price': item['price'],
                  'quantity': item['quantity'],
                })
            .toList();

      // Execute the update
      await billDocRef.update(updates);
      print("Bill updated successfully.");
    } catch (e) {
      print("Error updating bill: $e");
      throw CouldNotUpdateBillExcetion();
    }
  }

Future<void> deleteBill({required String billId}) async {
  try {
    final billDocRef = FirebaseFirestore.instance.collection('bills').doc(billId);
    await billDocRef.delete();
    print("Bill deleted successfully.");
  } catch (e) {
    print("Error deleting bill: $e");
    throw CouldNotDeleteBillException;
  }
}

}
