import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fotrah/views/Login_view.dart';
import 'firebase_options.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    title: 'Flutter Demo',
    theme: ThemeData(
      primarySwatch: Colors.blue,
    ),
    home: const LoginView(),
  ));
}

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
        title: const Text('Register'),
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
                          final userCredential = FirebaseAuth.instance
                              .createUserWithEmailAndPassword(
                            email: email,
                            password: password,
                          );
                          print(userCredential);
                        },
                        child: const Text('Register'),
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
