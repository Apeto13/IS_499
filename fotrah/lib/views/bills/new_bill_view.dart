import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fotrah/services/auth/CRUD/bills_service.dart';
import 'package:fotrah/services/auth/auth_service.dart';

class NewBillView extends StatefulWidget {
  const NewBillView({Key? key}) : super(key: key);

  @override
  State<NewBillView> createState() => _NewBillViewState();
}

class _NewBillViewState extends State<NewBillView> {
  late final billsService _billsService;
  late final TextEditingController _billDateController;
  late final TextEditingController _billTimeController;
  late final TextEditingController _coNameController;
  late final TextEditingController _cateNameController;
  late final TextEditingController _totalController;
  List<DatabaseItem> _items = [];
  DatabaseBill? _bill;
  bool _isCreatingBill = false;

  @override
  void initState() {
    super.initState();
    _billsService = billsService();
    _billDateController = TextEditingController();
    _billTimeController = TextEditingController();
    _coNameController = TextEditingController();
    _cateNameController = TextEditingController();
    _totalController = TextEditingController();
    _billsService.open();
    createNewBill();
  }

  @override
  void dispose() {
    _billDateController.dispose();
    _billTimeController.dispose();
    _coNameController.dispose(); // Dispose
    _cateNameController.dispose(); // Dispose
    _totalController.dispose();
    _billsService.close();
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add(DatabaseItem(
        itemID: _items.isNotEmpty
            ? _items.map((item) => item.itemID).reduce(max) + 1
            : 1,
        itemName: 'Example Item',
        type: 'Example Type',
        price: 0.0,
        quantity: 2,
        billID: _bill?.billID ?? 0,
      ));
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> createNewBill() async {
    // Prevent creation if currently creating a bill or if there are no items.
    if (_isCreatingBill || _items.isEmpty) return;

    _isCreatingBill = true;
    try {
      final currUser = AuthService.firebase().currentUser!;
      final email = currUser.email!;
      final owner = await _billsService.getOrCreateUser(email: email);

      // Only proceed with bill creation if _bill is null, ensuring no duplicate creations.


      if (_bill == null) {
        final newBill = await _billsService.createBill(
          ownerOfBill: owner,
          items: _items,
          coName: _coNameController.text,
          cateName: _cateNameController.text,
          billDate: _billDateController.text,
          billTime: _billTimeController.text,
          total: double.tryParse(_totalController.text) ??
              0.0, // Ensure to parse total here too.
        );

        setState(() {
          _bill = newBill;
        });
      }
    } catch (e) {
      print(e.toString());
    } finally {
      _isCreatingBill = false;
    }
  }

  void _updateBill() async {
    //print("Update bill started");
    if (_items.isEmpty || _totalController.text == "") {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please add items to the bill before saving.')));
      return;
    }
    //print(_bill.toString());
    if (_bill == null) {
      // If somehow we got here without a bill, try creating it first.
      await createNewBill();
      if (_bill == null) {
        // If still null, something went wrong, and we cannot proceed.
        return;
      }
    }

     try {
      final double total = double.tryParse(_totalController.text) ??
          0.0; // Parse total from input
      await _billsService.updateBill(
        billId: _bill!.billID,
        billDate: _billDateController.text,
        billTime: _billTimeController.text,
        items: _items,
        total: total, // Pass total to update
      );
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill updated successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error updating bill: $e')));
      print(e);
    }
  }

  Widget _buildItemInput(DatabaseItem item) {
    TextEditingController nameController = TextEditingController(text: '');
    TextEditingController typeController = TextEditingController(text: '');
    TextEditingController priceController = TextEditingController(text: '');
    TextEditingController quantityController = TextEditingController(text: '');

    nameController.addListener(() {
      item.itemName = nameController.text;
    });
    typeController.addListener(() {
      item.type = typeController.text;
    });
    priceController.addListener(() {
      var price = double.tryParse(priceController.text) ?? 0;
      item.price = price;
    });
    quantityController.addListener(() {
      var quantity = int.tryParse(quantityController.text) ?? 0;
      item.quantity = quantity;
    });

    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: nameController,
            decoration: InputDecoration(labelText: 'ItemName'),
            keyboardType: TextInputType.text,
            maxLines: null,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: typeController,
            decoration: InputDecoration(labelText: 'Type'),
            keyboardType: TextInputType.text,
            maxLines: null,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: priceController,
            decoration: InputDecoration(labelText: 'Price'),
            keyboardType: TextInputType.number,
            maxLines: null,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: quantityController,
            decoration: InputDecoration(labelText: 'Quantity'),
            keyboardType: TextInputType.number,
            maxLines: null,
          ),
        ),
        IconButton(
          icon: Icon(Icons.delete),
          onPressed: () {
            setState(() {
              _items.remove(item);
            });
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text("New Bill"),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _updateBill,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _cateNameController,
                decoration: InputDecoration(labelText: 'category Name'),
                keyboardType: TextInputType.text,
              ),
              TextFormField(
                controller: _coNameController,
                decoration: InputDecoration(labelText: 'Store Name'),
                keyboardType: TextInputType.text,
              ),
              TextFormField(
                controller: _billDateController,
                decoration: InputDecoration(labelText: 'Bill Date'),
                keyboardType: TextInputType.datetime,
                maxLines: null,
              ),
              TextFormField(
                controller: _billTimeController,
                decoration: InputDecoration(labelText: 'Bill Time'),
                keyboardType: TextInputType.datetime,
                maxLines: null,
              ),
              const SizedBox(height: 16),
              Text(
                'Items',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._items.map((item) => _buildItemInput(item)).toList(),
              TextFormField(
                controller: _totalController,
                decoration: const InputDecoration(labelText: 'Total'),
                keyboardType: TextInputType.number,
                onChanged: (_) => {}, // Optionally handle onChanged
              ),
              Center(
                child: ElevatedButton(
                  onPressed: _addItem,
                  child: Text('Add Item'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
