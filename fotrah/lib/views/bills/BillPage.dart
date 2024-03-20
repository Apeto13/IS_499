import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fotrah/constants/routes.dart';
import 'package:fotrah/enums/menu_action.dart';
import 'package:fotrah/services/auth/CRUD/bills_service.dart';
import 'package:fotrah/services/auth/auth_service.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late final billsService _billsService;
  String get userEmail => AuthService.firebase().currentUser!.email!;

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
    _billsService = billsService();
    _billsService.open();
    super.initState();
  }

  Future<void> _showDeleteConfirmationDialog(
      BuildContext context, int billId) async {
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
      await _billsService.deleteBill(id: billId);
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
        actions: [
          PopupMenuButton<MenuAction>(
            onSelected: (result) async {
              switch (result) {
                case MenuAction.Logout:
                  final shouldLogout = await showLogOutDialog(context);
                  if (shouldLogout) {
                    await AuthService.firebase().logOut();
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      loginRoute,
                      (route) => false,
                    );
                  }
                  break;
              }
            },
            itemBuilder: (context) {
              return const <PopupMenuEntry<MenuAction>>[
                PopupMenuItem<MenuAction>(
                  value: MenuAction.Logout,
                  child: Text('Log out'),
                ),
              ];
            },
          ),
        ],
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
      return FutureBuilder<DatabaseUser>(
        future: _billsService.getOrCreateUser(email: userEmail),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            return StreamBuilder<List<DatabaseBill>>(
              stream: _billsService.AllBills,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  final bills = snapshot.data!;
                  return ListView.builder(
                    itemCount: bills.length,
                    itemBuilder: (context, index) {
                      final bill = bills[index];
                      // Fetch and display company name using FutureBuilder
                      return FutureBuilder<DatabaseCompany>(
                        future: _billsService.getCompanyById(bill.companyID),
                        builder: (context, companySnapshot) {
                          print("Connection state: ${companySnapshot.connectionState}");
                          print("Has data: ${companySnapshot.hasData}");
                          print("Snapshot data: ${companySnapshot.data}");
                          if (companySnapshot.connectionState ==
                                  ConnectionState.done &&
                              companySnapshot.hasData) {
                            final company = companySnapshot.data!;
                            // Check if the company name is not null and not empty
                            final companyName = company.coName.isNotEmpty
                                ? company.coName
                                : "Unnamed Company";
                            return ListTile(
                              title: Text(
                                  companyName), // Use the companyName variable here
                              subtitle: Text(
                                  "Total: ${bill.total.toStringAsFixed(2)}\nDate: ${bill.billDate}\nTime: ${bill.billTime}"),
                              trailing: IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () => _showDeleteConfirmationDialog(
                                    context, bill.billID),
                              ),
                            );
                          } else {
                            // Display a placeholder or loading indicator while waiting for company details
                            return ListTile(
                              title: const Text("Loading company..."),
                              subtitle: Text(
                                  "Total: ${bill.total.toStringAsFixed(2)}"),
                              trailing: IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () => _showDeleteConfirmationDialog(
                                    context, bill.billID),
                              ),
                            );
                          }
                        },
                      );
                    },
                  );
                } else {
                  return const Center(child: Text("No bills available"));
                }
              },
            );
          } else {
            return const Center(child: CircularProgressIndicator());
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
      return Center(
        child: Text('Setting'),
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
