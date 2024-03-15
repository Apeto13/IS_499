import "dart:async";
import "package:flutter/material.dart";
import "package:fotrah/services/auth/CRUD/crud_exceptions.dart";
import "package:sqflite/sqflite.dart";
import "package:path_provider/path_provider.dart";
import "package:path/path.dart" show join;

class billsService {
  Database? _db;
  List<DatabaseBill> _bills = [];
  final _billsStreamController =
      StreamController<List<DatabaseBill>>.broadcast();
  static final billsService _shared = billsService._sharedInstance();
  billsService._sharedInstance();
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

  Future<DatabaseBill> updateBill({
    required int billId,
    double? total,
    String? billDate,
    String? billTime,
    List<DatabaseItem>? items,
  }) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final currentBill = await getBill(id: billId);

    if (total != null || billDate != null || billTime != null) {
      Map<String, Object?> updates = {};
      if (total != null) updates['total'] = total;
      if (billDate != null) updates['billDate'] = billDate;
      if (billTime != null) updates['billTime'] = billTime;

      final updatesCount = await db.update(
        billTable,
        updates,
        where: 'billID = ?',
        whereArgs: [billId],
      );
      if (updatesCount == 0) {
        throw CouldNotUpdateBill();
      }
    }

    if (items != null) {
      for (DatabaseItem item in items) {
        await db.update(
          itemTable,
          {
            'itemName': item.itemName,
            'type': item.type,
            'price': item.price,
            'quantity': item.quantity,
          },
          where: 'itemID = ? AND bill_ID = ?',
          whereArgs: [item.itemID, billId],
        );
      }
    }

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

  Future<DatabaseBill> createBill({
    required DatabaseUser ownerOfBill,
    List<DatabaseItem>? items,
    String? billDate,
    String? billTime,
  }) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    // Ensure the owner exists
    final dbUser = await getUser(email: ownerOfBill.email);
    if (dbUser != ownerOfBill) {
      throw CouldNotFindUser();
    }

    // Create the bill
    final billId = await db.insert(billTable, {
      'user_ID': ownerOfBill.userID,
      'billDate': billDate,
      'billTime': billTime,
      // Initially, total is set to 0; will be updated after items are added
      'total': 0,
    });

    double total = 0.0;

    // Add items if any
    if (items != null) {
      for (var item in items) {
        await addItemToBill(db, item, billId);
        total += item.price * item.quantity;
      }
    }

    // Update the bill with the total
    await db.update(billTable, {'total': total},
        where: 'billID = ?', whereArgs: [billId]);

    final bill = DatabaseBill(
      billID: billId,
      total: total,
      billDate: billDate ?? "",
      billTime: billTime ?? "",
      userID: ownerOfBill.userID,
      companyID: 0, // Assuming a default or a passed value
      categoryID: 0, // Assuming a default or a passed value
    );
    _bills.add(bill);
    _billsStreamController.add(_bills);
    return bill;
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

 DatabaseBill.fromRow(Map<String, Object?> map, [List<DatabaseItem> items = const []])
      : billID = map['billID'] as int,
        total = map['total'] as double,
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
  final int itemID;
  late final String itemName;
  late final String type;
  late final double price;
  late final int quantity;
  final int billID;

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
  final String address;
  final String branch;
  final int coPhone;

  DatabaseCompany({
    required this.companyId,
    required this.coName,
    required this.address,
    required this.branch,
    required this.coPhone,
  });

  DatabaseCompany.fromRow(Map<String, Object?> map)
      : companyId = map[companyIdCloumn] as int,
        coName = map[coNameColumn] as String,
        address = map[addressCloumn] as String,
        branch = map[branchCloumn] as String,
        coPhone = map[coPhoneCloumn] as int;

  @override
  String toString() => "None";

  @override
  bool operator ==(covariant DatabaseCompany other) =>
      companyId == other.companyId;

  @override
  // TODO: implement hashCode
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
