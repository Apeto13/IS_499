import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fotrah/firebase_options.dart';

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
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
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
        title: const Text('Login'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: FutureBuilder(
            future: Firebase.initializeApp(
              options: DefaultFirebaseOptions.currentPlatform,
            ),
            builder: (context, snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.done:
                  return Column(
                    children: [
                      SizedBox(height: 160.0),
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
                            final userCredential = FirebaseAuth.instance
                                .signInWithEmailAndPassword(
                              email: email,
                              password: password,
                            );
                            //print(userCredential);
                          } catch (e) {
                            print("L0000000000000000000000000000000000000000000000000L")
                            print(e.runtimeType);
                          }
                        },
                        child: const Text('Login'),
                      ),
                    ],
                  );
                default:
                  return const Text('Loading...');
              }
            },
          )),
    );
  }
}
