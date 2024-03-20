import "dart:async";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter/material.dart";
import "package:fotrah/services/auth/CRUD/crud_exceptions.dart";
import "package:sqflite/sqflite.dart";
import "package:path_provider/path_provider.dart";
import "package:path/path.dart" show join;

class billsService {
  Database? _db;
  List<DatabaseBill> _bills = [];
  late final StreamController<List<DatabaseBill>> _billsStreamController;
  static final billsService _shared = billsService._sharedInstance();
  billsService._sharedInstance() {
    _billsStreamController = StreamController<List<DatabaseBill>>.broadcast(
      onListen: () {
        _billsStreamController.sink.add(_bills);
      },
    );
  }
  factory billsService() => _shared;

  Stream<List<DatabaseBill>> get AllBills => _billsStreamController.stream;

  Future<DatabaseUser> getOrCreateUser({
    required String email,
  }) async {
    try {
      final user = await getUser(email: email);
      return user;
    } on CouldNotFindUser {
      final createdUser = await createUser(
        email: email,
        userName: 'DefaultUserName',
        phoneNum: 0,
      );
      return createdUser;
    } catch (_) {
      rethrow;
    }
  }

  Future<void> _cacheBills() async {
    final allBills = await getAllBill();
    _bills = allBills.toList();
    _billsStreamController.add(_bills);
  }

  Future<void> saveUserDetails({required String email, required String userName, required String phoneNumber}) async {
    int PhoneNumber = int.parse(phoneNumber);
    await createUser(
        email: email,
        userName: userName,
        phoneNum: PhoneNumber,
      );
  }

  Future<DatabaseBill> updateBill({
    required int billId,
    String? billDate,
    String? billTime,
    List<DatabaseItem>? items,
    required double total, // Add this line
  }) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    // No need to recalculate total here anymore
    // double total = 0.0;
    // if (items != null && items.isNotEmpty) {
    //   for (DatabaseItem item in items) {
    //     total += item.price * item.quantity;
    //   }
    // }

    // Update the bill's total along with any other details provided
    Map<String, Object?> updates = {
      'total': total, // Use the passed total
      if (billDate != null) 'billDate': billDate,
      if (billTime != null) 'billTime': billTime,
    };

    await db
        .update(billTable, updates, where: 'billID = ?', whereArgs: [billId]);

    // Fetch the updated bill to return
    final updatedBill = await getBill(id: billId);
    _bills.removeWhere((bill) => bill.billID == updatedBill.billID);
    _bills.add(updatedBill);
    _billsStreamController.add(_bills);
    return updatedBill;
  }

  Future<Iterable<DatabaseBill>> getAllBill() async {
    try {
      await _ensureDbIsOpen();
      final db = _getDatabaseOrThrow();
      final bills = await db.query(billTable);
      if (bills.isEmpty) {
        throw CouldNotFindBill(); // Throw error if no bills are found
      }
      final output = bills.map((BillRow) => DatabaseBill.fromRow(BillRow));
      return output;
    } catch (e) {
      print('Error occurred while fetching bills: $e');
      rethrow;
    }
  }

  Future<DatabaseBill> getBill({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final bills = await db
        .query(billTable, limit: 1, where: "billID = ?", whereArgs: [id]);
    if (bills.isEmpty) {
      throw CouldNotFindBill();
    } else {
      final bill = DatabaseBill.fromRow(bills.first);
      _bills.removeWhere((bill) => bill.billID == id);
      _bills.add(bill);
      _billsStreamController.add(_bills);
      return bill;
    }
  }

  Future<int> deleteAllBill() async {
    final db = _getDatabaseOrThrow();
    final numberOfDeletions = await db.delete(billTable);
    _bills = [];
    _billsStreamController.add(_bills);
    return numberOfDeletions;
  }

  Future<void> deleteBill({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount =
        await db.delete(billTable, where: 'billID = ?', whereArgs: [id]);
    if (deletedCount == 0) {
      throw CouldNotDeleteBill();
    } else {
      _bills.removeWhere((bill) => bill.billID == id);
      _billsStreamController.add(_bills);
    }
  }

  Future<DatabaseBill> createBill(
      {required DatabaseUser ownerOfBill,
      required String coName,
      required String cateName,
      List<DatabaseItem>? items,
      String? billDate,
      String? billTime,
      required double total}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    // Check if the company already exists and get the company_ID
    int companyId;
    try {
      companyId = await getCompanyId(coName);
    } on CouldNotFindCompany {
      // If the company does not exist, create it
      companyId = await createCompany(coName);
    }

    int cateId;
    try {
      cateId = await getCategoryId(cateName);
    } on CouldNotFindCategory {
      cateId = await createCategory(cateName);
    }

    // Ensure the owner exists
    final dbUser = await getUser(email: ownerOfBill.email);
    if (dbUser != ownerOfBill) {
      throw CouldNotFindUser();
    }

    // Create the bill with the company_ID
    final billId = await db.insert(billTable, {
      'user_ID': ownerOfBill.userID,
      'billDate': billDate,
      'billTime': billTime,
      'total': 0,
      'company_ID': companyId,
      'category_ID': cateId,
    });

    // double total = 0.0;

    // // Add items if any
    // if (items != null) {
    //   for (var item in items) {
    //     await addItemToBill(db, item, billId);
    //     total += item.price * item.quantity;
    //   }
    // }

    // // Update the bill with the total
    // await db.update(billTable, {'total': total},
    //     where: 'billID = ?', whereArgs: [billId]);

    // await db.insert(billTable, {
    //   'user_ID': ownerOfBill.userID,
    //   'billDate': billDate,
    //   'billTime': billTime,
    //   'total': total,
    //   'company_ID': companyId,
    //   'category_ID': cateId,
    // });

    final bill = DatabaseBill(
      billID: billId,
      total: total,
      billDate: billDate ?? "",
      billTime: billTime ?? "",
      userID: ownerOfBill.userID,
      companyID: companyId, // Assuming a default or a passed value
      categoryID: cateId, // Assuming a default or a passed value
    );
    _bills.add(bill);
    _billsStreamController.add(_bills);
    return bill;
  }

  Future<DatabaseCompany> getCompanyById(int companyId) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final companyDetails = await db.query(
      companyTable,
      where: 'companyID = ?',
      whereArgs: [companyId],
    );
    print(companyDetails);
    if (companyDetails.isEmpty) {
      throw CouldNotFindCompany();
    } else {
      final companyDetail = DatabaseCompany.fromRow(companyDetails.first);
      print(companyDetail);
      return companyDetail;
    }
  }

  Future<int> getCompanyId(String coName) async {
    final db = _getDatabaseOrThrow();
    final result = await db.query(
      companyTable,
      where: 'coName = ?',
      whereArgs: [coName],
    );
    if (result.isNotEmpty && result.first[companyIdColumn] != null) {
      return result.first[companyIdColumn] as int;
    } else {
      throw CouldNotFindCompany();
    }
  }

  Future<int> createCompany(String coName) async {
    final db = _getDatabaseOrThrow();
    // Insert a new company with the given coName and default values for other fields
    return await db.insert(companyTable, {
      'coName': coName,
    });
  }

  Future<int> getCategoryId(String cateName) async {
    final db = _getDatabaseOrThrow();
    final result = await db.query(
      cateTable,
      where: '$cateNameColumn = ?',
      whereArgs: [cateName],
    );
    if (result.isNotEmpty && result.first[cateIdColumn] != null) {
      return result.first[categoryIdCloumn] as int;
    } else {
      throw CouldNotFindCategory();
    }
  }

  Future<int> createCategory(String cateName) async {
    final db = _getDatabaseOrThrow();
    return await db.insert(cateTable, {
      "cateName": cateName,
    });
  }

  Future<void> addItemToBill(Database db, DatabaseItem item, int billId) async {
    await db.insert(itemTable, {
      'itemName': item.itemName,
      'type': item.type,
      'price': item.price,
      'quantity': item.quantity,
      'bill_ID': billId,
    });
  }

  Future<DatabaseUser> getUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final results = await db.query(
      userTable,
      limit: 1,
      where: "email = ?",
      whereArgs: [email.toLowerCase()],
    );
    if (results.isEmpty) {
      throw CouldNotFindUser();
    } else {
      return DatabaseUser.fromRow(results.first);
    }
  }

  Future<DatabaseUser> createUser(
      {required String email,
      required String userName,
      required int phoneNum}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final results = await db.query(
      userTable,
      limit: 1,
      where: "email = ?",
      whereArgs: [email.toLowerCase()],
    );
    if (results.isNotEmpty) {
      throw UserAlreadyExists();
    }
    final userId = await db.insert(userTable, {
      emailColumn: email.toLowerCase(),
      userNameColumn: userName.toLowerCase(),
      phoneNumColumn: phoneNum,
    });

    return DatabaseUser(
      userID: userId,
      email: email,
      phoneNum: phoneNum,
      userName: userName,
    );
  }

  Future<void> deleteUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      userTable,
      where: 'email= ?',
      whereArgs: [email.toLowerCase()],
    );
    if (deletedCount != 1) {
      throw CouldNotDeleteUser();
    }
  }

  Database _getDatabaseOrThrow() {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpen();
    } else {
      return db;
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpen();
    } else {
      await db.close();
      _db = null;
    }
  }

  Future<void> _ensureDbIsOpen() async {
    try {
      await open();
    } on DatabaseAlreadyOpenException {}
  }

  Future<void> open() async {
    if (_db != null) {
      throw DatabaseAlreadyOpenException();
    }
    try {
      final docsPath = await getApplicationCacheDirectory();
      final dbPath = join(docsPath.path, dbName);
      final db = await openDatabase(dbPath);
      _db = db;

      const createUserTable = ''' 
        CREATE TABLE IF NOT EXISTS "user" (
	        "userID"	INTEGER NOT NULL,
	        "email"	TEXT NOT NULL UNIQUE,
	        "phoneNum"	INTEGER NOT NULL UNIQUE,
	        "userName"	TEXT NOT NULL,
	        PRIMARY KEY("userID" AUTOINCREMENT)
          );
          ''';
      await db.execute(createUserTable);

      const createBillTable = '''
          CREATE TABLE IF NOT EXISTS "bill" (
	          "billID"	INTEGER,
	          "total"	NUMERIC NOT NULL,
	          "billDate"	TEXT,
	          "billTime"	TEXT,
	          "user_ID"	INTEGER NOT NULL,
	          "company_ID"	INTEGER NOT NULL,
	          "category_ID"	INTEGER NOT NULL,
	          FOREIGN KEY("user_ID") REFERENCES "user"("userID"),
          	FOREIGN KEY("category_ID") REFERENCES "Category"("CategoryID"),
          	FOREIGN KEY("company_ID") REFERENCES "Company"("CompanyID"),
          	PRIMARY KEY("billID" AUTOINCREMENT)
            );
          ''';
      await db.execute(createBillTable);

      const createItemTable = ''' CREATE TABLE IF NOT EXISTS "Item"  (
"itemID"	INTEGER,
"itemName"	TEXT NOT NULL,
"type"	TEXT,
"price"	NUMERIC NOT NULL,
"quantity"	INTEGER NOT NULL,
"bill_ID"	INTEGER NOT NULL,
FOREIGN KEY("bill_ID") REFERENCES "bill"("billID"),
PRIMARY KEY("itemID" AUTOINCREMENT)
);''';

      await db.execute(createItemTable);

      const createCategoryTable = ''' CREATE TABLE IF NOT EXISTS "Category" (
	"CategoryID"	INTEGER,
	"cateName"	TEXT NOT NULL,
	PRIMARY KEY("CategoryID" AUTOINCREMENT)
);''';
      await db.execute(createCategoryTable);
      const createCompanyTable = '''CREATE TABLE IF NOT EXISTS "Company" (
	"CompanyID"	INTEGER,
	"CoName"	TEXT,
	"address"	TEXT,
	"branch"	TEXT,
	"coPhoneNum"	INTEGER,
	PRIMARY KEY("CompanyID" AUTOINCREMENT)
); ''';
      await db.execute(createCompanyTable);
      await _cacheBills();
    } on MissingPlatformDirectoryException {
      throw UnableToGetDocumentsDirectory();
    }
  }
}

class DatabaseUser {
  final int userID;
  final String email;
  final int phoneNum;
  final String userName;

  @immutable
  const DatabaseUser({
    required this.userID,
    required this.email,
    required this.phoneNum,
    required this.userName,
  });

  DatabaseUser.fromRow(Map<String, Object?> map)
      : userID = map[idColumn] as int,
        email = map[emailColumn] as String,
        phoneNum = map[phoneNumColumn] as int,
        userName = map[userNameColumn] as String;

  @override
  String toString() =>
      "User Name = $userName, ID = $userID, email = $email, phone number = $phoneNum ";

  @override
  bool operator ==(covariant DatabaseUser other) => userID == other.userID;

  @override
  // TODO: implement hashCode
  int get hashCode => userID.hashCode;
}

class DatabaseBill {
  final int billID;
  final double total;
  final String billDate;
  final String billTime;
  final int userID;
  final int companyID;
  final int categoryID;
  final List<DatabaseItem> items;

  const DatabaseBill({
    required this.billID,
    required this.total,
    required this.billDate,
    required this.billTime,
    required this.userID,
    required this.companyID,
    required this.categoryID,
    this.items = const [],
  });

  DatabaseBill.fromRow(Map<String, Object?> map,
      [List<DatabaseItem> items = const []])
      : billID = map['billID'] as int,
        total = (map['total'] as num).toDouble(),
        billDate = map['billDate'] as String,
        billTime = map['billTime'] as String,
        userID = map['user_ID'] as int,
        companyID = map['company_ID'] as int,
        categoryID = map['category_ID'] as int,
        items = items;

  @override
  String toString() =>
      "bill ID = $billID, total = $total, billDate & Time = $billDate , $billTime ";

  @override
  bool operator ==(covariant DatabaseBill other) => billID == other.billID;

  @override
  // TODO: implement hashCode
  int get hashCode => billID.hashCode;
}

class DatabaseItem {
  late final int itemID;
  late final String itemName;
  late final String type;
  late final double price;
  late final int quantity;
  late final int billID;

  DatabaseItem({
    required this.itemID,
    required this.itemName,
    required this.type,
    required this.price,
    required this.quantity,
    required this.billID,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemID': itemID,
      'itemName': itemName,
      'type': type,
      'price': price,
      'quantity': quantity,
      'billID': billID,
    };
  }

  DatabaseItem.fromRow(Map<String, Object?> map)
      : itemID = map[itemIdcloumn] as int,
        itemName = map[itemNameCloumn] as String,
        type = map[typeCloumn] as String,
        price = map[priceCloumn] as double,
        quantity = map[quantityCloumn] as int,
        billID = map[billIditemColumn] as int;

  @override
  String toString() =>
      "item ID = $itemID, itemName = ${itemName ?? 'Unknown'}, quantity = $quantity";

  @override
  bool operator ==(covariant DatabaseItem other) => itemID == other.itemID;

  @override
  // TODO: implement hashCode
  int get hashCode => itemID.hashCode;
}

class DatabaseCompany {
  final int companyId;
  final String coName;
  final String? address;
  final String? branch;
  final int? coPhone;

  DatabaseCompany({
    required this.companyId,
    required this.coName,
    this.address,
    this.branch,
    this.coPhone,
  });

  factory DatabaseCompany.fromRow(Map<String, dynamic> map) {
    return DatabaseCompany(
      companyId: map['CompanyID'] as int,
      coName: map['CoName'] as String,
      address: map['address'] as String?, // Correctly handling as nullable
      branch: map['branch'] as String?, // Correctly handling as nullable
      coPhone:
          map['coPhoneNum'] as int?, // Fixed name to match your class field
    );
  }

  @override
  String toString() {
    return 'Company ID: $companyId, Name: $coName, Address: $address, Branch: $branch, Phone: $coPhone';
  }

  @override
  bool operator ==(covariant DatabaseCompany other) =>
      companyId == other.companyId;

  @override
  int get hashCode => companyId.hashCode;
}

class DatabaseCategory {
  final int categoryId;
  final String cateName;

  DatabaseCategory({required this.categoryId, required this.cateName});

  DatabaseCategory.fromRow(Map<String, Object?> map)
      : categoryId = map[categoryIdCloumn] as int,
        cateName = map[cateNameColumn] as String;
  @override
  String toString() => "None";

  @override
  bool operator ==(covariant DatabaseCategory other) =>
      categoryId == other.categoryId;

  @override
  // TODO: implement hashCode
  int get hashCode => categoryId.hashCode;
}

//user
const idColumn = "userID";
const emailColumn = "email";
const phoneNumColumn = "phoneNum";
const userNameColumn = "userName";
//bill
const billIdCloumn = "billID";
const totalCloumn = "total";
const billDateIdCloumn = "billDate";
const billTimeIdCloumn = "billTime";
const userIdColumn = "user_ID";
const companyIdColumn = "company_ID";
const cateIdColumn = "category_ID";
//item
const itemIdcloumn = "itemID";
const itemNameCloumn = "itemName";
const typeCloumn = 'type';
const priceCloumn = "price";
const quantityCloumn = "quantity";
const billIditemColumn = "bill_ID";
//Company
const companyIdCloumn = "companyID";
const coNameColumn = "CoName";
const addressCloumn = 'adress';
const branchCloumn = "branch";
const coPhoneCloumn = "coPhoneNum";
//Category
const categoryIdCloumn = "CategoryID";
const cateNameColumn = "cateName";
//other const
const dbName = "bills.db";
const userTable = "user";
const billTable = "bill";
const itemTable = "Item";
const companyTable = "Company";
const cateTable = "Category";
