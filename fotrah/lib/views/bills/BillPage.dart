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

  @override
  void dispose() {
    _billsService.close();
    super.dispose();
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
            const SizedBox(
                width: 48), 
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
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          // Use StreamBuilder to listen to bill changes
          return StreamBuilder<List<DatabaseBill>>(
            stream: _billsService.AllBills, // Adjusted for the correct type
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              } else if (snapshot.hasData) {
                final bills = snapshot.data!;
                // Check if there are bills
                if (bills.isEmpty) {
                  return const Center(child: Text("No bills found"));
                }
                // Display bills
                return ListView.builder(
                  itemCount: bills.length,
                  itemBuilder: (context, index) {
                    final bill = bills[index];
                    // Simple representation of a bill, you can customize this
                    return ListTile(
                      title: Text("Bill ID: ${bill.billID}"),
                      subtitle: Text("Total: ${bill.total.toString()}"),
                      onTap: () {
                        // Handle bill tap, if necessary
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
          // Handling loading state and errors
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
