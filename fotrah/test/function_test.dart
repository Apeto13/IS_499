import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fotrah/services/cloud/firebase_cloud_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('FirebaseCloudStorage Tests', () {

    setUpAll(() async {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp();
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    });
    test('createNewBill Test', () async {
      final FirebaseCloudStorage cloudStorage = FirebaseCloudStorage();
      final bill = await cloudStorage.createNewBill(
        userId: 'user123',
        total: 100.0,
        billDateTime: Timestamp.now(),
        coName: 'Test Company',
        categoryId: 'category123',
        items: [
          {
            'itemName': 'Item 1',
            'type': 'Type 1',
            'price': 50.0,
            'quantity': 2,
          },
          {
            'itemName': 'Item 2',
            'type': 'Type 2',
            'price': 25.0,
            'quantity': 3,
          },
        ],
      );
      expect(bill, isNotNull);
    });

    test('updateBill Test', () async {
      final FirebaseCloudStorage cloudStorage = FirebaseCloudStorage();

      // Assuming we have a bill ID to update
      final billId = 'bill123';

      // Assuming we have some updates to apply
      final total = 150.0;
      final billDateTime = Timestamp.now();

      // Assuming we have some items to update
      final items = [
        {
          'itemName': 'Updated Item 1',
          'type': 'Updated Type 1',
          'price': 75.0,
          'quantity': 2,
        },
        {
          'itemName': 'Updated Item 2',
          'type': 'Updated Type 2',
          'price': 30.0,
          'quantity': 3,
        },
      ];

      try {
        await cloudStorage.updateBill(
          billId: billId,
          total: total,
          billDateTime: billDateTime,
          items: items,
        );

        // If no exceptions are thrown, the update was successful
        expect(true, true);
      } catch (e) {
        // If an exception is thrown, the update failed
        expect(true, false);
      }
    });

    test('getBills Test', () async {
      final FirebaseCloudStorage cloudStorage = FirebaseCloudStorage();

      // Assuming we have a user ID to retrieve bills for
      final userId = 'user123';

      try {
        final bills = await cloudStorage.getBills(userId: userId);

        // Assuming bills are retrieved successfully
        expect(bills, isNotNull);
      } catch (e) {
        // If an exception is thrown, getting bills failed
        expect(true, false);
      }
    });

    test('deleteBill Test', () async {
      final FirebaseCloudStorage cloudStorage = FirebaseCloudStorage();

      // Assuming we have a bill ID to delete
      final billId = 'bill123';

      try {
        await cloudStorage.deleteBill(billId: billId);

        // If no exceptions are thrown, the deletion was successful
        expect(true, true);
      } catch (e) {
        // If an exception is thrown, the deletion failed
        expect(true, false);
      }
    });
  });
}
