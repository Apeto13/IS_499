import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fotrah/firebase_options.dart';
import 'package:fotrah/views/Login_view.dart';
import 'package:fotrah/views/Register_view.dart';
import 'package:fotrah/views/Verify_email_view.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    title: 'Flutter Demo',
    theme: ThemeData(
      primarySwatch: Colors.blue,
    ),
    home: const HomePage(),
    routes: {
      '/Login': (context) => const LoginView(),
      '/Register': (context) => const RegisterView(),
      '/Verify_email':(context) => const VerifyEmailView(),
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
                return const LoginView();
              default:
                return const Center(child: CircularProgressIndicator());
            }
          },
        ));
  }
}

//abdulrahmanalsalman13@gmail.com

