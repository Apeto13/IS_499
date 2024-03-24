import 'package:flutter/material.dart';
import 'package:fotrah/constants/routes.dart';
import 'package:fotrah/services/cloud/cloud_bill.dart';
import 'package:fotrah/services/cloud/firebase_cloud_storage.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BillDetailsPage extends StatefulWidget {
  const BillDetailsPage({Key? key}) : super(key: key);

  @override
  _BillDetailsPageState createState() => _BillDetailsPageState();
}

class _BillDetailsPageState extends State<BillDetailsPage> {
  late final FirebaseCloudStorage _cloudStorage;
  late final TextEditingController _dateAndTimeController;
  late final TextEditingController _coNameController;
  late final TextEditingController _cateNameController;
  late final TextEditingController _totalController;
  List<Map<String, dynamic>> _items = [];
  DateTime? _selectedBillDateTime;
  CloudBill? _currentBill;


 @override
void initState() {
  super.initState();
  _cloudStorage = FirebaseCloudStorage();
  _dateAndTimeController = TextEditingController();
  _coNameController = TextEditingController();
  _cateNameController = TextEditingController();
  _totalController = TextEditingController();

  // Asynchronously fetch the bill details and update the UI accordingly
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final CloudBill? bill = ModalRoute.of(context)?.settings.arguments as CloudBill?;
    if (bill != null) {
      _currentBill = bill;
      _selectedBillDateTime = bill.billDateAndTime.toDate();
      String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(_selectedBillDateTime!);
      String companyName = await _cloudStorage.getCompanyName(bill.companyId);
      String categoryName = await _cloudStorage.getCategoryName(bill.categoryId);
      List<Map<String, dynamic>> items = List.from(bill.items);

      // Use setState to update the UI with the fetched details
      setState(() {
        _dateAndTimeController.text = formattedDate;
        _coNameController.text = companyName;
        _cateNameController.text = categoryName;
        _totalController.text = bill.total.toString();
        _items = items;
      });
    }
  });
}

  @override
  void dispose() {
    _dateAndTimeController.dispose();
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

  Future<void> _updateBill() async {
    // Implement logic to update bill
    // Use _cloudStorage to call a method to update bill
    final bill = ModalRoute.of(context)?.settings.arguments as CloudBill;
    double? total = double.tryParse(_totalController.text);
    final Timestamp billDateTime =
        Timestamp.fromDate(_selectedBillDateTime ?? DateTime.now());
    try {
      final updateBill = await _cloudStorage.updateBill(
          billId: bill.id,
          total: total,
          billDateTime: billDateTime,
          items: _items
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bill updated successfully')));
      Navigator.of(context).pushNamed(fotrahRoute);
    } catch (e) {
      print("e");
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
        title: const Text("Edit Bill"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _updateBill,
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
                child: Text(_selectedBillDateTime == null
                    ? 'Select Date & Time'
                    : 'Selected Date & Time: ${_selectedBillDateTime!}'),
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
                  subtitle: Text(
                      "Type: ${item['type']}, Price: ${item['price']}, Quantity: ${item['quantity']}"),
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
