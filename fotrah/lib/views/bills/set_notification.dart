import 'package:flutter/material.dart';
import 'package:fotrah/constants/routes.dart';
import 'package:fotrah/services/auth/auth_service.dart';
import 'package:fotrah/services/cloud/firebase_cloud_storage.dart';

class SetNotificationPage extends StatefulWidget {
  const SetNotificationPage({Key? key}) : super(key: key);

  @override
  State<SetNotificationPage> createState() => _SetNotificationPageState();
}

class _SetNotificationPageState extends State<SetNotificationPage> {
  double _currentBudget = 0;
  final FirebaseCloudStorage _cloudStorage = FirebaseCloudStorage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Set Budget'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Text(
              'Set budget for this month',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20), // Provides spacing between text and slider
            Slider(
              value: _currentBudget,
              min: 0,
              max: 10000,
              divisions:
                  100, // To allow finer control, adjust this value as needed
              label: _currentBudget.round().toString(),
              onChanged: (double value) {
                setState(() {
                  _currentBudget = value;
                });
              },
            ),
            SizedBox(height: 20), // Provides spacing between slider and button
            ElevatedButton(
              onPressed: () async {
                final String userId = AuthService.firebase()
                    .currentUser!
                    .email; // Ensure this matches your auth logic
                final DateTime now = DateTime.now();
                await _cloudStorage.setUserBudget(
                    userId: userId,
                    budget: _currentBudget,
                    year: now.year,
                    month: now.month
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Budget set to ${_currentBudget.round()}')),
                );
                Navigator.of(context).pushNamed(fotrahRoute);
              },
              child: Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }
}
