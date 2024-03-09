import 'package:flutter/material.dart';

class NewBillView extends StatefulWidget {
  const NewBillView({super.key});

  @override
  State<NewBillView> createState() => _NewBillViewState();
}

class _NewBillViewState extends State<NewBillView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:AppBar(
        backgroundColor: Colors.blue,
        title: const Text("New Bill"),
      ),
      body: const Text("Write your new Bill here..."),
    );
  }
}