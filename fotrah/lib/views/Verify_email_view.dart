import 'package:flutter/material.dart';
import 'package:fotrah/constants/routes.dart';
import 'package:fotrah/services/auth/auth_service.dart';

class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({super.key});

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Email Verifcation"),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          const Text(
              "We've sent you an email verification, Please verify your account."),
          const Text("if You haven't reseaved an email please click here "),
          TextButton(
              onPressed: () async {
                await AuthService.firebase().sendEmailVerificaiton();
              },
              child: const Text('Send email verification')
          ),
          TextButton(onPressed: () async {
            await AuthService.firebase().logOut();
            Navigator.of(context).pushNamedAndRemoveUntil(registerRoute, (route) => false);
          }, child: const Text("Restart"))
        ],
      ),
    );
  }
}
