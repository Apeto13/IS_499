import 'package:flutter/material.dart';
import 'package:fotrah/constants/routes.dart';
import 'package:fotrah/services/auth/auth_exceptions.dart';
import 'package:fotrah/services/auth/auth_service.dart';
import 'package:fotrah/utilities/show_error_dialog.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController _email;
  late final TextEditingController _password;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController();
    _password = TextEditingController();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Login",
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
        shape: RoundedRectangleBorder(
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _email,
              decoration: const InputDecoration(
                hintText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _password,
              decoration: const InputDecoration(
                hintText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: const Text('Login'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context)
                  .pushNamedAndRemoveUntil(registerRoute, (route) => false),
              child: const Text("Don't have an account? Register"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _login() async {
    final email = _email.text;
    final password = _password.text;
    try {
      await AuthService.firebase().logIn(email: email, password: password);
      final user = AuthService.firebase().currentUser;
      if (user?.isEmailVerified ?? false) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil(fotrahRoute, (route) => false);
      } else {
        Navigator.of(context)
            .pushNamedAndRemoveUntil(VerifyEmailRoute, (route) => false);
      }
    } on UserNotFoundAuthException {
      await showErrorDialog(context, "User not found");
    } on WrongPasswordAuthException {
      await showErrorDialog(context, "Wrong password");
    } on GenericAuthException {
      await showErrorDialog(context, "Authentication error");
    }
  }
}
