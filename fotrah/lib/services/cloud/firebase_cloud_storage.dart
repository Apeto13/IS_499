import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fotrah/services/cloud/cloud_bill.dart';
import 'package:fotrah/services/cloud/cloud_storage_exceptions.dart';
import 'package:fotrah/enums/menu_action.dart';

class FirebaseCloudStorage {
  static final FirebaseCloudStorage _shared =
      FirebaseCloudStorage._sharedInstance();
  FirebaseCloudStorage._sharedInstance();
  factory FirebaseCloudStorage() => _shared; // This is a singleton

  final bills = FirebaseFirestore.instance.collection('bill');

  Future<double> getTotalSpendingForTimeFrame(
      TimeFrame timeFrame, String userId) async {
    DateTime now = DateTime.now();
    DateTime start;
    DateTime end;

    switch (timeFrame) {
      case TimeFrame.AllTime:
        start = DateTime(2000); 
        end = DateTime(now.year, now.month, now.day + 1)
            .subtract(Duration(seconds: 1)); 
        break;
      case TimeFrame.thisYear:
        start = DateTime(now.year);
        end = DateTime(now.year + 1).subtract(Duration(days: 1));
        break;
      case TimeFrame.thisMonth:
        start = DateTime(now.year, now.month);
        end = DateTime(now.year, now.month + 1).subtract(Duration(days: 1));
        break;
    }

    final querySnapshot = await FirebaseFirestore.instance
        .collection('bill')
        .where('userId', isEqualTo: userId)
        .where('billDateAndTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('billDateAndTime', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    double totalSpent = querySnapshot.docs.fold(0, (sum, doc) {
      return sum + (doc.data()['total'] as num).toDouble();
    });

    return totalSpent;
  }

  Future<double> getBudgetForTimeFrame(
      TimeFrame timeFrame, String userId) async {
    DateTime now = DateTime.now();
    final budgetRef = FirebaseFirestore.instance
        .collection('budgets')
        .doc('$userId-${now.year}-${now.month}');
    final doc = await budgetRef.get();
    if (!doc.exists) return 0;
    double monthlyBudget = doc.data()?['budget'] ?? 0;
    if (timeFrame == TimeFrame.AllTime || timeFrame == TimeFrame.thisYear)
      return monthlyBudget * 12;

    return monthlyBudget;
  }

  Future<void> setUserBudget(
      {required String userId,
      required double budget,
      required int year,
      required int month}) async {
    final budgetRef = FirebaseFirestore.instance
        .collection('budgets')
        .doc('$userId-$year-$month');
    await budgetRef.set({
      'budget': budget,
      'year': year,
      'month': month,
    });
  }

  Future<Map<String, double>> getTotalSpendingPerCategoryForUser(
      String userId, TimeFrame timeFrame) async {
    Map<String, double> spendingPerCategory = {};
    List<String> categories = [
      "Housing",
      "Utilities",
      "Transportation",
      "Groceries",
      "Dining Out",
      "Healthcare",
      "Entertainment",
      "Personal Care",
      "Clothing",
      "Education",
      "Childcare",
      "Pets",
      "Savings and Investments",
      "Gifts and Donations",
      "Travel",
      "Debts",
      "Other"
    ];

    DateTime now = DateTime.now();
    DateTime start;
    DateTime end;

    // Adjust start and end based on the time frame
    switch (timeFrame) {
      case TimeFrame.AllTime:
        start = DateTime(2000); 
        end = DateTime(now.year, now.month, now.day + 1)
            .subtract(Duration(seconds: 1)); 
        break;
      case TimeFrame.thisYear:
        start = DateTime(now.year);
        end = DateTime(now.year + 1).subtract(Duration(days: 1));
        break;
      case TimeFrame.thisMonth:
        start = DateTime(now.year, now.month);
        end = DateTime(now.year, now.month + 1).subtract(Duration(days: 1));
        break;
    }

    FirebaseFirestore db = FirebaseFirestore.instance;
    for (String category in categories) {
      DocumentReference categoryRef = db.collection('category').doc(category);

      final querySnapshot = await db
          .collection('bill')
          .where('userId', isEqualTo: userId)
          .where('categoryId',
              isEqualTo: db.doc('category/$category')) // Use the reference path
          .where('billDateAndTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('billDateAndTime',
              isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      double totalSpentInCategory = querySnapshot.docs.fold(0, (sum, doc) {
        final docData = doc.data() as Map<String, dynamic>;
        final total = docData['total'] as num;
        return sum + total.toDouble();
      });
      spendingPerCategory[category] = totalSpentInCategory;
    }

    return spendingPerCategory;
  }

  Future<bool> checkBudgetNotification(
      {required String userId, required int year, required int month}) async {
    final startOfMonth = DateTime(year, month);
    final endOfMonth = DateTime(year, month + 1).subtract(Duration(seconds: 1));

    final budgetDoc = await FirebaseFirestore.instance
        .collection('budgets')
        .doc('$userId-$year-$month')
        .get();
    if (!budgetDoc.exists) {
      return false;
    }

    double budget = budgetDoc.data()?['budget'] ?? 0;
    double totalSpent = await _getSumTotalOfUser(
        userId: userId,
        startOfMonth: Timestamp.fromDate(startOfMonth),
        endOfMonth: Timestamp.fromDate(endOfMonth));
    return totalSpent >= (budget - 50) && totalSpent <= budget;
  }

  Future<double> _getSumTotalOfUser({
    required String userId,
    required Timestamp startOfMonth,
    required Timestamp endOfMonth,
  }) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('bill')
        .where('userId', isEqualTo: userId)
        .where('billDateAndTime', isGreaterThanOrEqualTo: startOfMonth)
        .where('billDateAndTime', isLessThanOrEqualTo: endOfMonth)
        .get();
    double totalSpent = 0;
    for (var doc in querySnapshot.docs) {
      final docData = doc.data() as Map<String, dynamic>;
      final total =
          docData['total'] as num?; // Assuming 'total' is stored as a number
      if (total != null) {
        totalSpent += total.toDouble();
      }
    }
    return totalSpent;
  }

  Future<Map<String, String?>> getUserDetails(String email) async {
    DocumentSnapshot userSnapshot =
        await FirebaseFirestore.instance.collection('user').doc(email).get();
    if (userSnapshot.exists) {
      Map<String, dynamic> userData =
          userSnapshot.data() as Map<String, dynamic>;
      return {
        'userName': userData['userName'],
        'phoneNumber': userData['phoneNumber'],
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
    final userDocRef = FirebaseFirestore.instance.collection('user').doc(email);

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
    required String categoryId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      // Create company and get their references
      final companyRef = await createCompany(coName);

      // Assuming categories are pre-defined and you have their IDs
      final categoryRef =
          FirebaseFirestore.instance.collection('category').doc(categoryId);

      DocumentReference billRef = await bills.add({
        'userId': userId,
        'total': total,
        'billDateAndTime': billDateTime,
        'companyId': companyRef,
        'categoryId': categoryRef,
        'items': items.map((item) {
          return {
            'itemName': item['itemName'],
            'type': item['type'],
            'price': item['price'],
            'quantity': item['quantity'],
          };
        }).toList(),
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
    String? categoryId,
    List<Map<String, dynamic>>? items,
  }) async {
    try {
      final billDocRef =
          FirebaseFirestore.instance.collection('bill').doc(billId);

      Map<String, Object?> updates = {};
      if (total != null) updates['total'] = total;
      if (billDateTime != null) updates['billDateAndTime'] = billDateTime;
      if (categoryId != null)
        updates['categoryId'] =
            FirebaseFirestore.instance.collection('category').doc(categoryId);
      if (items != null) {
        updates['items'] = items
            .map((item) => {
                  'itemName': item['itemName'],
                  'type': item['type'],
                  'price': item['price'],
                  'quantity': item['quantity'],
                })
            .toList();
      }

      await billDocRef.update(updates);
      print("Bill updated successfully.");
    } catch (e) {
      print("Error updating bill: $e");
      throw CouldNotUpdateBillException(); // Ensure this exception is defined
    }
  }

  Future<void> deleteBill({required String billId}) async {
    try {
      // First, retrieve the bill document to get the company reference
      final billDocRef =
          FirebaseFirestore.instance.collection('bill').doc(billId);
      final billDoc = await billDocRef.get();
      if (billDoc.exists) {
        final data = billDoc.data() as Map<String, dynamic>;
        final companyRef = data['companyId'] as DocumentReference?;

        // Delete the bill document
        await billDocRef.delete();
        print("Bill deleted successfully.");

        // If there's a company reference, attempt to delete the company document
        if (companyRef != null) {
          await companyRef.delete();
          print("Associated company deleted successfully.");
        }
      }
    } catch (e) {
      print("Error deleting bill or associated company: $e");
      throw CouldNotDeleteBillException(); // Make sure this exception is defined somewhere
    }
  }
}
