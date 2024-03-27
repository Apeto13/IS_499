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
  String? _selectedCategoryId;
  List<String> _categoryNames = [];

  @override
  void initState() {
    super.initState();
    _cloudStorage = FirebaseCloudStorage();
    _dateAndTimeController = TextEditingController();
    _coNameController = TextEditingController();
    _cateNameController = TextEditingController();
    _totalController = TextEditingController();
    fetchCategories();
    // Asynchronously fetch the bill details and update the UI accordingly
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final CloudBill? bill =
          ModalRoute.of(context)?.settings.arguments as CloudBill?;
      if (bill != null) {
        _currentBill = bill;
        _selectedBillDateTime = bill.billDateAndTime.toDate();
        String formattedDate =
            DateFormat('dd/MM/yyyy HH:mm').format(_selectedBillDateTime!);
        String companyName = await _cloudStorage.getCompanyName(bill.companyId);
        String categoryName =
            await _cloudStorage.getCategoryName(bill.categoryId);
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

  void onCategorySelected(String? newValue) {
    if (newValue != null) {
      setState(() {
        _selectedCategoryId = newValue;
      });
    }
  }

  void fetchCategories() async {
    // Fetch the document that contains the list of category names
    final snapshot = await FirebaseFirestore.instance
        .collection('category')
        .doc('categoryId')
        .get();
    final data = snapshot.data();
    final List<dynamic> categories = data?['cateNames'] ?? [];

    // Update the state with fetched category names
    setState(() {
      _categoryNames = List<String>.from(
          categories); // This ensures we have a list of strings
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
    final String categoryId = _selectedCategoryId ?? 'Other';
    final bill = ModalRoute.of(context)?.settings.arguments as CloudBill;
    double? total = double.tryParse(_totalController.text);
    final Timestamp billDateTime =
        Timestamp.fromDate(_selectedBillDateTime ?? DateTime.now());

    try {
      await _cloudStorage.updateBill(
        billId: bill.id,
        total: total,
        billDateTime: billDateTime,
        categoryId: categoryId,
        items: _items,
      );
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Bill updated successfully')));
      Navigator.of(context).pushNamed(fotrahRoute);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to update bill: $e')));
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
        title: const Text(
          "Edit Bill",
          style: TextStyle(
            fontSize: 25.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _updateBill,
          ),
        ],
        centerTitle: true,
        elevation: 10, // Adds shadow to the AppBar
        shadowColor: Colors.blueAccent.shade100, // Customizes the shadow color
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom:
                Radius.circular(30), // Adds a curve to the bottom of the AppBar
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue,
                Colors.blueAccent.shade700
              ], // Gradient colors
              begin: Alignment.bottomRight,
              end: Alignment.topLeft,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: _pickDateAndTime,
                        child: Text(_selectedBillDateTime == null
                            ? 'Select Date & Time'
                            : 'Selected Date & Time: ${DateFormat('dd/MM/yyyy HH:mm').format(_selectedBillDateTime!)}'),
                      ),
                      TextFormField(
                        controller: _coNameController,
                        decoration: const InputDecoration(
                          labelText: "Store Name",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.store),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCategoryId,
                        onChanged: onCategorySelected,
                        items: _categoryNames
                            .map<DropdownMenuItem<String>>((String category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text("Items", style: Theme.of(context).textTheme.headline6),
              ..._items.map((item) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(item['itemName']),
                    subtitle: Text(
                        "Type: ${item['type']}, Price: ${item['price'].toStringAsFixed(2)}, Quantity: ${item['quantity']}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => setState(() => _items.remove(item)),
                    ),
                  ),
                );
              }).toList(),
              ElevatedButton(
                onPressed: _addItem,
                child: const Text('Add Item'),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _totalController,
                decoration: const InputDecoration(
                  labelText: "Total Amount",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
