import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fotrah/services/cloud/cloud_bill.dart';
import 'package:fotrah/services/cloud/cloud_storage_exceptions.dart';
import 'package:fotrah/enums/menu_action.dart';

// import 'package:intl/intl.dart';
// import 'package:tuple/tuple.dart';
// import 'package:collection/collection.dart';

class FirebaseCloudStorage {
  static final FirebaseCloudStorage _shared =
      FirebaseCloudStorage._sharedInstance();
  FirebaseCloudStorage._sharedInstance();
  factory FirebaseCloudStorage() => _shared;

  final bills = FirebaseFirestore.instance.collection('bill');

  Future<List<CloudBill>> getBillsByCompanyName(String companyName) async {
    try {
      print(companyName);
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('bill')
          .where('companyId', isEqualTo: companyName)
          .get();
      final List<CloudBill> bills = querySnapshot.docs.map((doc) {
        return CloudBill.fromSnapshot(doc);
      }).toList();
      print(bills);
      return bills;
    } catch (e) {
      print("Error fetching bills by company name: $e");
      return [];
    }
  }

  Future<List<BarChartGroupData>> getSpendingDataBasedOnTimeFrame(
      String userId, TimeFrame timeFrame) async {
    DateTime now = DateTime.now();
    DateTime start, end;

    if (timeFrame == TimeFrame.AllTime) {
      start = DateTime(now.year - 5);
      end = DateTime(now.year + 1, 1, 0);
    } else if (timeFrame == TimeFrame.thisYear) {
      start = DateTime(now.year);
      end = DateTime(now.year + 1, 1, 0);
    } else {
      // TimeFrame.thisMonth
      start = DateTime(now.year, now.month);
      end = DateTime(now.year, now.month + 1, 0);
    }

    var querySnapshot = await FirebaseFirestore.instance
        .collection('bill')
        .where('userId', isEqualTo: userId)
        .where('billDateAndTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('billDateAndTime', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    List<BarChartGroupData> barGroups = [];
    Map<int, double> totals = {};

    for (var doc in querySnapshot.docs) {
      DateTime date = (doc['billDateAndTime'] as Timestamp).toDate();
      double total = doc['total'].toDouble();
      int groupKey = timeFrame == TimeFrame.thisMonth ? date.day : date.month;

      totals.update(groupKey, (existing) => existing + total,
          ifAbsent: () => total);
    }

    totals.entries.forEach((entry) {
      barGroups.add(BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value,
            color: Colors.blue,
          ),
        ],
      ));
    });


    barGroups.sort((a, b) => a.x.compareTo(b.x));

    return barGroups;
  }

  Future<List<FlSpot>> getTotalSpendingOverTime(
      String userId, TimeFrame timeFrame) async {
    DateTime start, end;
    DateTime now = DateTime.now();
    List<FlSpot> spots = [];

    switch (timeFrame) {
      case TimeFrame.AllTime: // 5 years
        start = DateTime(now.year - 5);
        end = DateTime(now.year, now.month + 1).subtract(Duration(days: 1));
        break;
      case TimeFrame.thisYear: // only this year
        start = DateTime(now.year);
        end = DateTime(now.year + 1).subtract(Duration(days: 1));
        break;
      case TimeFrame.thisMonth:
        start = DateTime(now.year, now.month);
        end = DateTime(now.year, now.month + 1).subtract(Duration(days: 1));
        break;
    }
    var querySnapshot = await FirebaseFirestore.instance
        .collection('bill')
        .where('userId', isEqualTo: userId)
        .where('billDateAndTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('billDateAndTime', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('billDateAndTime')
        .get();
    querySnapshot.docs.forEach((doc) {
      DateTime billDate = (doc.data()['billDateAndTime'] as Timestamp).toDate();
      double total = (doc.data()['total'] as num).toDouble();
      double xValue;
      if (timeFrame == TimeFrame.AllTime) {
        xValue = (billDate.year - start.year) * 12.0 + billDate.month;
      } else if (timeFrame == TimeFrame.thisYear) {
        xValue = billDate.month.toDouble();
      } else if (timeFrame == TimeFrame.thisMonth) {
        xValue = billDate.day.toDouble();
      } else {
        xValue = 0;
      }
      spots.add(FlSpot(xValue, total));
    });
    return spots;
  }

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
          docData['total'] as num?; 
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
        'email': userSnapshot.id, 
      };
    } else {
      throw CouldNotGetUserInfoException(); 
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
      throw CouldNotUpdateUserException(); 
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
    return companyRef; 
  }

  Future<DocumentReference> createCategory(String cateName) async {
    final categoryRef =
        FirebaseFirestore.instance.collection('category').doc(cateName);
    final categoryDoc = await categoryRef.get();
    if (!categoryDoc.exists) {
      await categoryRef.set(
          {'cateName': cateName}); 
    }
    return categoryRef; 
  }

  Future<String> getCompanyId(DocumentReference companyRef) async {
    try {
      final docSnapshot = await companyRef.get();
      if (docSnapshot.exists) {
        return docSnapshot
            .id; 
      } else {
        throw CouldNotFindCompanyException(); 
      }
    } catch (e) {
      print('Error fetching company ID: $e');
      throw CouldNotFindCompanyException();
    }
  }

  Future<String> getCategoryId(DocumentReference categoryRef) async {
    try {
      final docSnapshot = await categoryRef.get();
      if (docSnapshot.exists) {
        return docSnapshot.id; 
      } else {
        throw CouldNotFindCategoryException(); 
      }
    } catch (e) {
      print('Error fetching category ID: $e');
      throw CouldNotFindCategoryException(); 
    }
  }

  Future<String> getCompanyName(DocumentReference companyRef) async {
    try {
      DocumentSnapshot companyDoc = await companyRef.get();
      if (companyDoc.exists) {
        Map<String, dynamic>? companyData =
            companyDoc.data() as Map<String, dynamic>?;
        if (companyData != null && companyData.containsKey('coName')) {
          return companyData['coName'] ?? "Unknown Company";
        } else {
          return "Field 'coName' not found in document";
        }
      } else {
        return "Document does not exist";
      }
    } catch (e) {
      print("Error fetching company name: $e");
      return "Error Fetching Name"; 
    }
  }

  Future<String> getCategoryName(DocumentReference categoryRef) async {
    try {
      DocumentSnapshot categorySnapshot = await categoryRef.get();
      if (categorySnapshot.exists) {
        Map<String, dynamic> data =
            categorySnapshot.data() as Map<String, dynamic>;
        return data['cateName'] ??
            "Unknown Category";
      } else {
        return "Unknown Category"; 
      }
    } catch (e) {
      print("Error fetching category name: $e");
      return "Error Fetching Name"; 
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
      final companyRef = await createCompany(coName);

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
    String? companyId,
    List<Map<String, dynamic>>? items,
  }) async {
    try {
      final billDocRef =
          FirebaseFirestore.instance.collection('bill').doc(billId);

      // Fetch the bill document
      final billDocSnapshot = await billDocRef.get();
      if (!billDocSnapshot.exists) {
        throw Exception("Bill document not found");
      }
      final currentCompanyId =
          billDocSnapshot.data()?['companyId'] as DocumentReference?;
      String currentCompanyName = '';
      if (currentCompanyId != null) {
        await currentCompanyId.delete();
      }
      if (companyId != null) {
        await createCompany(companyId);
      }

      Map<String, Object?> updates = {};
      if (total != null) updates['total'] = total;
      if (billDateTime != null) updates['billDateAndTime'] = billDateTime;
      if (categoryId != null)
        updates['categoryId'] =
            FirebaseFirestore.instance.collection('category').doc(categoryId);
      if (companyId != null)
        updates['companyId'] =
            FirebaseFirestore.instance.collection('company').doc(companyId);
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
      print("post-company name: $companyId");
      print("pre-company name: $currentCompanyName");
      await billDocRef.update(updates);
      print("Bill updated successfully.");
    } catch (e) {
      print("Error updating bill: $e");
      throw CouldNotUpdateBillException();
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
