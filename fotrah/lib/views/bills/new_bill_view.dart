import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fotrah/services/cloud/firebase_cloud_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fotrah/constants/routes.dart';

class NewBillView extends StatefulWidget {
  const NewBillView({Key? key}) : super(key: key);

  @override
  State<NewBillView> createState() => _NewBillViewState();
}

class _NewBillViewState extends State<NewBillView> {
  late final FirebaseCloudStorage _cloudStorage;
  DateTime? _selectedBillDateTime;
  late final TextEditingController _coNameController;
  late final TextEditingController _cateNameController;
  late final TextEditingController _totalController;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _cloudStorage = FirebaseCloudStorage();
    _coNameController = TextEditingController();
    _cateNameController = TextEditingController();
    _totalController = TextEditingController();
  }

  @override
  void dispose() {
    _coNameController.dispose();
    _cateNameController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  void _pickDateAndTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2025),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      _selectedBillDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }
  
  Future<void> _createNewBill() async {
    final userId = FirebaseAuth.instance.currentUser?.email;
    if (userId == null) return;
    final double total = double.tryParse(_totalController.text) ?? 0.0;
    final Timestamp billDateTime = Timestamp.fromDate(_selectedBillDateTime ?? DateTime.now());

    try {
      final createdBill = await _cloudStorage.createNewBill(
        userId: userId,
        total: total,
        billDateTime: billDateTime,
        cateName: _cateNameController.text, // Implement your logic to obtain companyId
        coName: _coNameController.text, // Implement your logic to obtain categoryId
        items: _items,
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bill created successfully')));
      Navigator.of(context).pushNamed(fotrahRoute);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create bill: $e')));
    }
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final itemNameController = TextEditingController();
        final itemTypeController = TextEditingController();
        final itemPriceController = TextEditingController();
        final itemQuantityController = TextEditingController();
        return AlertDialog(
          title: Text("Add New Item"),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                TextField(
                  controller: itemNameController,
                  decoration: InputDecoration(hintText: "Item Name"),
                ),
                TextField(
                  controller: itemTypeController,
                  decoration: InputDecoration(hintText: "Type"),
                ),
                TextField(
                  controller: itemPriceController,
                  decoration: InputDecoration(hintText: "Price"),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: itemQuantityController,
                  decoration: InputDecoration(hintText: "Quantity"),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Add"),
              onPressed: () {
                setState(() {
                  _items.add({
                    'itemName': itemNameController.text,
                    'type': itemTypeController.text,
                    'price': double.tryParse(itemPriceController.text) ?? 0.0,
                    'quantity': int.tryParse(itemQuantityController.text) ?? 0,
                  });
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Bill"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _createNewBill,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton(
                onPressed: _pickDateAndTime,
                child: Text(_selectedBillDateTime == null ? 'Select Date & Time' : 'Selected Date & Time: ${_selectedBillDateTime!}'),
              ),
              TextField(
                controller: _coNameController,
                decoration: InputDecoration(hintText: "Store Name"),
              ),
              TextField(
                controller: _cateNameController,
                decoration: InputDecoration(hintText: "Category Name"),
              ),
              SizedBox(height: 20),
              Text("Items", style: Theme.of(context).textTheme.headline6),
              ..._items.map((item) {
                return ListTile(
                  title: Text(item['itemName']),
                  subtitle: Text("Type: ${item['type']}, Price: ${item['price']}, Quantity: ${item['quantity']}"),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => setState(() => _items.remove(item)),
                  ),
                );
              }).toList(),
              ElevatedButton(
                onPressed: _addItem,
                child: Text('Add Item'),
              ),
              TextField(
                controller: _totalController,
                decoration: InputDecoration(hintText: "Total Amount"),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}