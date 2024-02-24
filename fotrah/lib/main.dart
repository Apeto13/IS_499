import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fotrah/constants/routes.dart';
import 'package:fotrah/firebase_options.dart';
import 'package:fotrah/views/Login_view.dart';
import 'package:fotrah/views/Register_view.dart';
import 'package:fotrah/views/Verify_email_view.dart';
import 'package:fotrah/views/MainPage_view.dart';
import 'dart:developer' as devtools show log;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    title: 'Flutter Demo',
    theme: ThemeData(
      primarySwatch: Colors.blue,
    ),
    home: const HomePage(),
    routes: {
      loginRoute: (context) => const LoginView(),
      registerRoute: (context) => const RegisterView(),
      VerifyEmailRoute: (context) => const VerifyEmailView(),
      fotrahRoute: (context) => const MainPage(),
    },
  ));
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: FutureBuilder(
          future: Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          ),
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.done:
                final user = FirebaseAuth.instance.currentUser;
                devtools.log(user.toString());
                if (user != null) {
                  if (user.emailVerified) {
                    return const MainPage();
                  } else {
                    return const VerifyEmailView();
                  }
                } else {
                  return const LoginView();
                }
              //return const Text("Done!");
              default:
                return const Center(child: CircularProgressIndicator());
            }
          },
        ));
  }
}
