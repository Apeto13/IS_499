import 'package:flutter/material.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms and Conditions'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Center(
            child: Text(
              '''Introduction

Welcome to fotarh! By accessing or using our app, you agree to be bound by these terms and conditions. If you disagree with any part of these terms, you may not access the service.

User Conduct

You agree to use fotarh only for lawful purposes and in a way that does not infringe the rights of, restrict, or inhibit anyone else's use and enjoyment of the app. Prohibited behavior includes harassing or causing distress or inconvenience to any other user, transmitting obscene or offensive content, or disrupting the normal flow of dialogue within our app.

Copyright and Intellectual Property

The content, layout, design, data, databases, and graphics on this app are protected by Saudi Arabia and other international intellectual property laws and are owned by fotarh or its licensors. No part of the app may be reproduced, stored in a retrieval system, or transmitted in any form without our prior written permission.

Privacy Policy

Your privacy is important to us. Our Privacy Policy, which is incorporated into these terms by this reference, sets out how we will use personal information you provide to us or we collect about you. By using fotarh, you agree to be bound by our Privacy Policy.

Limitation of Liability

fotarh will not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of or inability to use the app.

Governing Law

These terms shall be governed by and construed in accordance with the laws of Saudi Arabia, without giving effect to any principles of conflicts of law.

Changes to Terms

We reserve the right, at our sole discretion, to modify or replace these terms at any time. By continuing to access or use our app after those revisions become effective, you agree to be bound by the revised terms.

Contact Us

If you have any questions about these terms, please contact us at abdulrahmanalsalman13@gmail.com.''',
              textAlign: TextAlign.justify,
            ),
          ),
        ),
      ),
    );
  }
}
