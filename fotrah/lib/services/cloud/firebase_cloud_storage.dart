import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fotrah/services/cloud/cloud_bill.dart';
import 'package:fotrah/services/cloud/cloud_storage_exceptions.dart';

class FirebaseCloudStorage {
  static final FirebaseCloudStorage _shared =
      FirebaseCloudStorage._sharedInstance();
  FirebaseCloudStorage._sharedInstance();
  factory FirebaseCloudStorage() => _shared; // This is a singleton

  final bills = FirebaseFirestore.instance.collection('bill');


  Future<Map<String, String?>> getUserDetails(String email) async {
    DocumentSnapshot userSnapshot =
        await FirebaseFirestore.instance.collection('user').doc(email).get();
    if (userSnapshot.exists) {
      Map<String, dynamic> userData =
          userSnapshot.data() as Map<String, dynamic>;
      return {
        'userName': userData['userName'],
        'phoneNum': userData['phoneNumber'],
        'email': userSnapshot.id, // ID of the document is the email
      };
    } else {
      throw CouldNotGetUserInfoException(); // Make sure to define this exception
    }
  }

  Future<void> updateUserDetails({
    required String email,
    String? userName,
    String? phoneNumber,
  }) async {
    final userDocRef =
        FirebaseFirestore.instance.collection('user').doc(email);

    Map<String, Object?> updates = {};
    if (userName != null) updates['userName'] = userName;
    if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;

    try {
      await userDocRef.update(updates);
      print("User details updated successfully.");
    } catch (e) {
      print("Error updating user details: $e");
      throw CouldNotUpdateUserException(); // Make sure to define this exception
    }
  }

  Future<void> saveUserDetails({
    required String email,
    required String userName,
    required String phoneNumber,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('user').doc(email).set({
        'userName': userName,
        'phoneNumber': phoneNumber,
        // Add any additional fields you need
      });
    } catch (e) {
      print('Error saving user details: $e');
      throw CouldNotSaveUserExceprion();
    }
  }

  Future<DocumentReference> createCompany(String coName) async {
    final companyRef =
        FirebaseFirestore.instance.collection('company').doc(coName);
    final companyDoc = await companyRef.get();
    if (!companyDoc.exists) {
      await companyRef.set({'coName': coName});
    }
    return companyRef; // Returns a reference to the company document
  }

  Future<DocumentReference> createCategory(String cateName) async {
    final categoryRef =
        FirebaseFirestore.instance.collection('category').doc(cateName);
    final categoryDoc = await categoryRef.get();
    if (!categoryDoc.exists) {
      await categoryRef.set(
          {'cateName': cateName}); // Add any other category fields you need
    }
    return categoryRef; // Returns a reference to the category document
  }

  Future<String> getCompanyId(DocumentReference companyRef) async {
    try {
      final docSnapshot = await companyRef.get();
      if (docSnapshot.exists) {
        return docSnapshot
            .id; // or docSnapshot.data()['someFieldName'] if you need a specific field
      } else {
        throw CouldNotFindCompanyException(); // Custom exception, ensure you define it
      }
    } catch (e) {
      print('Error fetching company ID: $e');
      throw CouldNotFindCompanyException(); // Use a more specific exception if necessary
    }
  }

  Future<String> getCategoryId(DocumentReference categoryRef) async {
    try {
      final docSnapshot = await categoryRef.get();
      if (docSnapshot.exists) {
        return docSnapshot.id; // Or any specific field from the document
      } else {
        throw CouldNotFindCategoryException(); // Custom exception, ensure you define it
      }
    } catch (e) {
      print('Error fetching category ID: $e');
      throw CouldNotFindCategoryException(); // Use a more specific exception if necessary
    }
  }

  Future<String> getCompanyName(DocumentReference companyRef) async {
    try {
      DocumentSnapshot companyDoc = await companyRef.get();
      if (companyDoc.exists) {
        Map<String, dynamic> companyData =
            companyDoc.data() as Map<String, dynamic>;
        return companyData['coName'] ?? "Unknown Company";
      } else {
        return "Unknown Company";
      }
    } catch (e) {
      print("Error fetching company name: $e");
      return "Error";
    }
  }

  Future<String> getCategoryName(DocumentReference categoryRef) async {
    try {
      DocumentSnapshot categorySnapshot = await categoryRef.get();
      if (categorySnapshot.exists) {
        Map<String, dynamic> data =
            categorySnapshot.data() as Map<String, dynamic>;
        return data['cateName'] ??
            "Unknown Category"; // Assuming 'cateName' is the field
      } else {
        return "Unknown Category"; // Handle case where the document does not exist
      }
    } catch (e) {
      print("Error fetching category name: $e");
      return "Error Fetching Name"; // Handle any errors gracefully
    }
  }

  Future<CloudBill> createNewBill({
    required String userId,
    required double total,
    required Timestamp billDateTime,
    required String coName,
    required String cateName,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      // Create company and category and get their references
      final companyRef = await createCompany(coName);
      final categoryRef = await createCategory(cateName);

      DocumentReference billRef = await bills.add({
        'userId': userId,
        'total': total,
        'billDateAndTime': billDateTime,
        'companyId': companyRef,
        'categoryId': categoryRef,
        'items': items
            .map((item) => {
                  'itemName': item['itemName'],
                  'type': item['type'],
                  'price': item['price'],
                  'quantity': item['quantity'],
                })
            .toList(),
      });
      DocumentSnapshot billSnapshot = await billRef.get();
      CloudBill createdBill = CloudBill.fromSnapshot(billSnapshot);

      print("Bill created successfully.");
      return createdBill;
    } catch (e) {
      print("Error creating bill: $e");
      throw Exception("Failed to create bill");
    }
  }

  Stream<Iterable<CloudBill>> getBills({required String userId}) {
    return bills.snapshots().map((event) => event.docs
        .map((doc) => CloudBill.fromSnapshot(doc))
        .where((bill) => bill.id == userId));
  }

  Future<List<CloudBill>> getBillsForUser({required String userId}) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('bill')
          .where('userId', isEqualTo: userId) // Filter by the specific user ID
          .get();
      Iterable<CloudBill> AllBills =
          querySnapshot.docs.map((doc) => CloudBill.fromSnapshot(doc));

      return AllBills.toList();
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
      final billDocRef =
          FirebaseFirestore.instance.collection('bill').doc(billId);

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
      final billDocRef =
          FirebaseFirestore.instance.collection('bill').doc(billId);
      await billDocRef.delete();
      print("Bill deleted successfully.");
    } catch (e) {
      print("Error deleting bill: $e");
      throw CouldNotDeleteBillException;
    }
  }
}
