import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fotrah/constants/routes.dart';
import 'package:fotrah/services/auth/auth_service.dart';
import 'package:fotrah/services/cloud/firebase_cloud_storage.dart';

class Profile extends StatefulWidget {
  const Profile({Key? key}) : super(key: key);

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  TextEditingController _userNameController = TextEditingController();
  TextEditingController _phoneNumController = TextEditingController();
  String _email = ''; // Initialize _email with a default value
  late final FirebaseCloudStorage _cloudStorage;
  bool _isLoading = true; // Add a loading state

  @override
  void initState() {
    super.initState();
    _cloudStorage = FirebaseCloudStorage();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final userId = AuthService.firebase().currentUser?.email;
    if (userId != null) {
      try {
        final userDetails = await _cloudStorage.getUserDetails(userId);
        setState(() {
          _userNameController.text = userDetails['userName'] ?? '';
          _phoneNumController.text = userDetails['phoneNumber'] ?? '';
          _email = userDetails['email'] ?? '';
          _isLoading = false; // Set loading to false once data is fetched
        });
      } catch (e) {
        print("Error fetching user data: $e");
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUserProfile() async {
    final userId = AuthService.firebase().currentUser?.email;
    if (userId == null) {
      print("Error: User is not logged in.");
      return;
    }
    try {
      await _cloudStorage.updateUserDetails(
        email: userId,
        userName: _userNameController.text,
        phoneNumber: _phoneNumController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      Navigator.of(context).pushNamed(fotrahRoute);
    } catch (e) {
      print("Error updating user profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    }
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _phoneNumController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(
        title: const Text(
          "Profile",
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
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading indicator while fetching data
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: <Widget>[
                  TextFormField(
                    controller: _userNameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                  ),
                  TextFormField(
                    controller: _phoneNumController,
                    decoration: const InputDecoration(labelText: 'Phone Number'),
                    keyboardType: TextInputType.phone,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text('Email: $_email'), // Email is displayed but not editable
                  ),
                  ElevatedButton(
                    onPressed: _updateUserProfile,
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
            ),
    );
  }
}
