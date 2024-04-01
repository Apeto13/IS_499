import 'package:flutter/material.dart';
import 'package:fotrah/constants/routes.dart';

class ScanOrManual extends StatelessWidget {
  const ScanOrManual({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Add New Bill",
          style: TextStyle(
            fontSize: 25.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        elevation: 10,
        shadowColor: Colors.blueAccent.shade100,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.blueAccent.shade700],
              begin: Alignment.bottomRight,
              end: Alignment.topLeft,
            ),
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Card(
                elevation: 4.0,
                child: ListTile(
                  title: const Text('Scan Bill'),
                  onTap: () {
                    Navigator.of(context).popAndPushNamed(fotrahRoute); 
                  },
                  trailing: const Icon(Icons.camera_alt),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 4.0,
                child: ListTile(
                  title: const Text('Enter Bill Manually'),
                  onTap: () {
                    Navigator.of(context).popAndPushNamed(newBillRoute); 
                  },
                  trailing: const Icon(Icons.edit),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
