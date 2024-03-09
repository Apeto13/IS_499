
import 'package:flutter/material.dart';
import 'package:fotrah/constants/routes.dart';
import 'package:fotrah/firebase_options.dart';
import 'package:fotrah/services/auth/auth_service.dart';
import 'package:fotrah/views/Login_view.dart';
import 'package:fotrah/views/Register_view.dart';
import 'package:fotrah/views/Verify_email_view.dart';
import 'package:fotrah/views/bills/BillPage.dart';
import 'dart:developer' as devtools show log;

import 'package:path/path.dart';

import 'views/bills/new_bill_view.dart';

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
      newBillRoute: (context) => const NewBillView(),
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
          future: AuthService.firebase().initialize(),
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.done:
                final user = AuthService.firebase().currentUser;
                devtools.log(user.toString());
                if (user != null) {
                  if (user.isEmailVerified) {
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
        )
      );
  }
}
