import 'package:cloud_firestore/cloud_firestore.dart';

class CloudBill {
  final String id;
  final double total;
  final Timestamp billDateAndTime;
  final String userId;
  final DocumentReference companyId;
  final DocumentReference categoryId;
  final List<dynamic> items;

  CloudBill({
    required this.id,
    required this.total,
    required this.billDateAndTime,
    required this.userId,
    required this.companyId,
    required this.categoryId,
    required this.items,
  });

  factory CloudBill.fromSnapshot(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    // print("Total type: ${data['total'].runtimeType}, value: ${data['total']}");
    // print("company type: ${data['companyId'].runtimeType}, value: ${data['companyId']}");
    // print("categoryId type: ${data['categoryId'].runtimeType}, value: ${data['categoryId']}");
    return CloudBill(
      id: doc.id,
      total: (data['total'] as num).toDouble(),
      billDateAndTime: data['billDateAndTime'] as Timestamp? ??
          Timestamp.fromDate(DateTime.now()),
      userId: data['userId'],
      companyId: data['companyId'] as DocumentReference,
      categoryId: data['categoryId'] as DocumentReference,
      items: data['items'] ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'total': total,
      'billDateAndTime': billDateAndTime,
      'userId': userId,
      'companyId': companyId,
      'categoryId': categoryId,
      'items': items,
    };
  }
}

class CloudCompany {
  final String id;
  final String coName;
  final String? address;
  final String? branch;
  final int? coPhone;

  CloudCompany({
    required this.id,
    required this.coName,
    this.address,
    this.branch,
    this.coPhone,
  });

  factory CloudCompany.fromSnapshot(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CloudCompany(
      id: doc.id,
      coName: data['coName'],
      address: data['address'],
      branch: data['branch'],
      coPhone: data['coPhone'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'coName': coName,
      'address': address,
      'branch': branch,
      'coPhone': coPhone,
    };
  }
}

class CloudCategory {
  final String id;
  final List<String> cateNames;

  CloudCategory({
    required this.id,
    required this.cateNames,
  });

  factory CloudCategory.fromSnapshot(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    List<String> names = List.from(data['cateNames'] ?? []);
    return CloudCategory(
      id: doc.id,
      cateNames: names,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cateNames': cateNames,
    };
  }
}

class CloudUser {
  final String id;
  final String? userName;
  final String? phoneNum;
  final String email;

  CloudUser({
    required this.id,
    this.userName,
    this.phoneNum,
    required this.email,
  });

  factory CloudUser.fromSnapshot(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CloudUser(
      id: doc.id,
      userName: data['userName'] ?? '',
      phoneNum: data['phoneNumber'] ?? '',
      email: data['email'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userName': userName,
      'phoneNum': phoneNum,
      'email': email,
    };
  }
}
