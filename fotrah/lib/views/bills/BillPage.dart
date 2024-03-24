import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fotrah/constants/routes.dart';
import 'package:fotrah/enums/menu_action.dart';
import 'package:fotrah/services/auth/CRUD/bills_service.dart';
import 'package:fotrah/services/auth/auth_service.dart';
import 'package:fotrah/services/cloud/cloud_bill.dart';
import 'package:fotrah/services/cloud/firebase_cloud_storage.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late final FirebaseCloudStorage _cloudStorage;
  late String _userId;

  // UI
  int _currentIndex = 0;
  static const List<Widget> _bodyWidgets = [
    Icon(Icons.home),
    Icon(Icons.analytics),
    Icon(Icons.notifications),
    Icon(Icons.settings),
  ];

  @override
  void initState() {
    _cloudStorage = FirebaseCloudStorage();
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    final user = AuthService.firebase().currentUser?.email;
    if (user != null) {
      _userId = user; // Here we fetch and store the user's UID
      setState(() {}); // Trigger a rebuild if needed
    }
  }

  Future<void> _showDeleteConfirmationDialog(
      BuildContext context, String billId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Bill'),
        content: Text('Are you sure you want to delete this bill?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    // If confirmed, delete the bill and refresh the list (if needed)
    if (shouldDelete ?? false) {
      await _cloudStorage.deleteBill(billId: billId);
      setState(
          () {}); // This will refresh the UI if your list is built within this Widget.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Main Page"),
        backgroundColor: Colors.blue,
        // actions: [
        //   PopupMenuButton<MenuAction>(
        //     onSelected: (result) async {
        //       switch (result) {
        //         case MenuAction.Logout:
        //           final shouldLogout = await showLogOutDialog(context);
        //           if (shouldLogout) {
        //             await AuthService.firebase().logOut();
        //             Navigator.of(context).pushNamedAndRemoveUntil(
        //               loginRoute,
        //               (route) => false,
        //             );
        //           }
        //           break;
        //       }
        //     },
        //     itemBuilder: (context) {
        //       return const <PopupMenuEntry<MenuAction>>[
        //         PopupMenuItem<MenuAction>(
        //           value: MenuAction.Logout,
        //           child: Text('Log out'),
        //         ),
        //       ];
        //     },
        //   ),
        // ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed(newBillRoute);
        },
        child: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            // Home
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {
                setState(() {
                  _currentIndex = 0;
                });
              },
            ),
            // Analytics
            IconButton(
              icon: const Icon(Icons.analytics),
              onPressed: () {
                setState(() {
                  _currentIndex = 1;
                });
              },
            ),
            const SizedBox(width: 48),
            // Notifications
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                setState(() {
                  _currentIndex = 2;
                });
              },
            ),
            // Settings
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                setState(() {
                  _currentIndex = 3;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_currentIndex == 0) {
      return FutureBuilder<List<CloudBill>>(
        future: _cloudStorage.getBillsForUser(
            userId: _userId), // Assuming this method exists
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (snapshot.hasData) {
            final billsList = snapshot.data!;
            if (billsList.isEmpty) {
              return const Center(child: Text("No bills available"));
            }
            return ListView.builder(
              itemCount: billsList.length,
              itemBuilder: (context, index) {
                final bill = billsList[index];
                return FutureBuilder<String>(
                  future: _cloudStorage.getCompanyName(bill.companyId),
                  builder: (context, companySnapshot) {
                    // Your existing builder logic
                    String companyName =
                        companySnapshot.data ?? "Unknown Company";
                    DateTime billDate = bill.billDateAndTime.toDate();
                    String formattedDate =
                        DateFormat('dd/MM/yyyy HH:mm').format(billDate);
                    return ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          BillDetailRoute,
                          arguments: bill,
                        );
                      },
                      child: ListTile(
                        title: Text(companyName),
                        subtitle: Text(
                            "Total: ${bill.total.toStringAsFixed(2)}\nDate: $formattedDate"),
                      ),
                    );
                  },
                );
              },
            );
          } else {
            return const Center(child: Text("No bills available"));
          }
        },
      );
    } else if (_currentIndex == 1) {
      return Center(
        child: Text('Analytics'),
      );
    } else if (_currentIndex == 2) {
      return Center(
        child: Text('No notification for now'),
      );
    } else if (_currentIndex == 3) {
      return ListView(
        children: <Widget>[
          Card(
            child: ListTile(
              title: Text('Profile'),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(context).pushNamed(ProfileRoute);
              },
            ),
          ),
          Card(
            child: ListTile(
              title: Text('Set Notification'),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Navigate to set notification
              },
            ),
          ),
          Card(
            child: ListTile(
              title: Text('Logout'),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () async {
                final shouldLogout = await showLogOutDialog(context);
                if (shouldLogout) {
                  await AuthService.firebase().logOut();
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil(loginRoute, (route) => false);
                }
              },
            ),
          ),
        ],
      );
    } else {
      return Center(
        child: Text('Setting'),
      );
    }
  }
}

Future<bool> showLogOutDialog(BuildContext context) {
  return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('LogOut'),
          content: const Text('Are you sure you want to LogOut?'),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: const Text("cancel")),
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: const Text("Log out"))
          ],
        );
      }).then((value) => value ?? false);
}
