
import 'package:flutter/material.dart';
import 'package:fotrah/constants/routes.dart';
import 'package:fotrah/services/auth/auth_service.dart';
import 'package:fotrah/views/Login_view.dart';
import 'package:fotrah/views/Register_view.dart';
import 'package:fotrah/views/Verify_email_view.dart';
import 'package:fotrah/views/bills/BillPage.dart';
import 'package:fotrah/views/bills/analysis.dart';
import 'package:fotrah/views/bills/bill_details.dart';
import 'package:fotrah/views/bills/profile.dart';
import 'package:fotrah/views/bills/set_notification.dart';
import 'package:fotrah/views/bills/terms_and_conditions.dart';
import 'dart:developer' as devtools show log;
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
      BillDetailRoute: (context) => const BillDetailsPage(),
      ProfileRoute:(context) => const Profile(),
      SetNotificationRoute: (context) => const SetNotificationPage(),
      TermsAndConditionsRoute: (context) => const TermsAndConditionsPage(),
      AnalyticsRoute:(context) => const AnalyticsPage(),
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
