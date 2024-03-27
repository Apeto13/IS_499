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
            onPressed: () {
              Navigator.of(context).pop(true);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Bill deleted successfully')));
            },
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
        title: const Text(
          "Main Page",
          style: TextStyle(
            fontSize: 25.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        elevation: 10, // Adds shadow to the AppBar
        shadowColor: Colors.blueAccent.shade100, // Customizes the shadow color
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom:
                Radius.circular(30), // Adds a curve to the bottom of the AppBar
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue,
                Colors.blueAccent.shade700
              ], // Gradient colors
              begin: Alignment.bottomRight,
              end: Alignment.topLeft,
            ),
          ),
        ),
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
                Navigator.of(context).pushNamed(AnalyticsRoute);
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
        future: _cloudStorage.getBillsForUser(userId: _userId),
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
                    String companyName =
                        companySnapshot.data ?? "Unknown Company";
                    DateTime billDate = bill.billDateAndTime.toDate();
                    String formattedDate =
                        DateFormat('dd/MM/yyyy HH:mm').format(billDate);
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(companyName,
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            "Total: ${bill.total.toStringAsFixed(2)}\nDate: $formattedDate"),
                        trailing: Wrap(
                          spacing: 12, // space between two icons
                          children: <Widget>[
                            IconButton(
                              icon: Icon(Icons.visibility,
                                  color: Theme.of(context).primaryColor),
                              onPressed: () {
                                Navigator.of(context).pushNamed(
                                  BillDetailRoute,
                                  arguments: bill,
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showDeleteConfirmationDialog(
                                  context, bill.id),
                            ),
                          ],
                        ),
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
    } else if (_currentIndex == 2) {
      // Assuming this is within a StatefulWidget that has access to _cloudStorage
      final String userId = AuthService.firebase().currentUser!.email;
      final DateTime now = DateTime.now();
      return FutureBuilder<bool>(
        future: _cloudStorage.checkBudgetNotification(
            userId: userId, year: now.year, month: now.month),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData && snapshot.data!) {
            // User is nearing their budget limit
            return  Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 4, // Adds shadow to the card
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize
                          .min, // Minimize the column's size to fit its children
                      children: [
                        const Text(
                          'Budget Alert',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'You are close to reaching your monthly budget!',
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20), // Spacing before the button
                        ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'You are close to reaching your monthly budget!',
                                  style: TextStyle(
                                      color: Colors.red), // Make text color red
                                ),
                                backgroundColor: Colors
                                    .white, // Optional: Change background color
                              ),
                            );
                            Navigator.of(context).pushNamed(SetNotificationRoute);
                          },
                          child: const Text('Check Budget'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          } else {
            return const Center(
              child: Text('No notification for now'),
            );
          }
        },
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
                Navigator.of(context).pushNamed(SetNotificationRoute);
              },
            ),
          ),
          Card(
            child: ListTile(
              title: Text('Terms & conditons'),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(context).pushNamed(TermsAndConditionsRoute);
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
      return FutureBuilder<List<CloudBill>>(
        future: _cloudStorage.getBillsForUser(userId: _userId),
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
                    String companyName =
                        companySnapshot.data ?? "Unknown Company";
                    DateTime billDate = bill.billDateAndTime.toDate();
                    String formattedDate =
                        DateFormat('dd/MM/yyyy HH:mm').format(billDate);
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(companyName,
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            "Total: ${bill.total.toStringAsFixed(2)}\nDate: $formattedDate"),
                        trailing: Wrap(
                          spacing: 12, // space between two icons
                          children: <Widget>[
                            IconButton(
                              icon: Icon(Icons.visibility,
                                  color: Theme.of(context).primaryColor),
                              onPressed: () {
                                Navigator.of(context).pushNamed(
                                  BillDetailRoute,
                                  arguments: bill,
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showDeleteConfirmationDialog(
                                  context, bill.id),
                            ),
                          ],
                        ),
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
