import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fotrah/firebase_options.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  _RegisterViewState createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  late final TextEditingController _userName;
  late final TextEditingController _phoneNumber;
  late final TextEditingController _email;
  late final TextEditingController _password;

  @override
  void initState() {
    _userName = TextEditingController();
    _phoneNumber = TextEditingController();
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _userName.dispose();
    _phoneNumber.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register"),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          SizedBox(height: 150.0),
          TextField(
            controller: _userName,
            decoration: InputDecoration(
              hintText: '  username',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25.0),
              ),
            ),
          ),
          SizedBox(height: 5.0),
          TextField(
              controller: _phoneNumber,
              decoration: InputDecoration(
                hintText: '  Phone Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
              ),
              keyboardType: TextInputType.phone),
          SizedBox(height: 5.0),
          TextField(
            controller: _email,
            decoration: InputDecoration(
              hintText: '  Email',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25.0),
              ),
            ),
            enableSuggestions: false,
            autocorrect: false,
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 5.0),
          TextField(
            controller: _password,
            decoration: InputDecoration(
              hintText: '  Password',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25.0),
              ),
            ),
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
          ),
          SizedBox(height: 5.0),
          TextButton(
            onPressed: () async {
              final email = _email.text;
              final password = _password.text;
              try {
                final userCredential =
                    await FirebaseAuth.instance.createUserWithEmailAndPassword(
                  email: email,
                  password: password,
                );
                print(userCredential);
              } on FirebaseAuthException catch (e) {
                print(e.code);
                if (e.code == 'weak-password')
                  print("Weak password! ");
                else if (e.code == "email-already-in-use")
                  print("This email is already in use! ");
                else if (e.code == "invalid-email")
                  print("This email is invaild! ");
              }
            },
            child: const Text('Register'),
          ),
          TextButton(
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/Login',
                  (route) => false,
                );
              },
              child: const Text("Login"))
        ],
      ),
    );
  }
}
