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
  List<DatabaseItem> _items = [];
  DatabaseBill? _bill;

  @override
  void initState() {
    super.initState();
    _billsService = billsService();
    _billDateController = TextEditingController();
    _billTimeController = TextEditingController();
    _billsService.open();
    // Initially create a new bill when the page is loaded
    createNewBill();
  }

  @override
  void dispose() {
    _billDateController.dispose();
    _billTimeController.dispose();
    _billsService.close();
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add(DatabaseItem(
        itemID: _items.isNotEmpty ? _items.map((item) => item.itemID).reduce(max) + 1 : 1,
        itemName: '',
        type: '',
        price: 0.0,
        quantity: 0,
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
    final currUser = AuthService.firebase().currentUser!;
    final email = currUser.email!;
    final owner = await _billsService.getOrCreateUser(email: email);

    final newBill = await _billsService.createBill(
      ownerOfBill: owner,
      items: _items,
      billDate: _billDateController.text,
      billTime: _billTimeController.text,
    );

    setState(() {
      _bill = newBill;
    });
  }

  void _updateBill() async {
    if (_bill == null) {
      await createNewBill();
      return;
    }
    try {
      await _billsService.updateBill(
        billId: _bill!.billID,
        billDate: _billDateController.text,
        billTime: _billTimeController.text,
        items: _items,
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bill updated successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating bill: $e')));
    }
  }

  Widget _buildItemInput(DatabaseItem item) {
  // Assuming each item has unique TextEditingController instances.
  // If not, you'll need to initialize them elsewhere and ensure they are disposed of properly.
  TextEditingController nameController = TextEditingController(text: item.itemName);
  TextEditingController typeController = TextEditingController(text: item.type);
  TextEditingController priceController = TextEditingController(text: item.price.toString());
  TextEditingController quantityController = TextEditingController(text: item.quantity.toString());

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
          keyboardType: TextInputType.multiline,
        ),
      ),
      SizedBox(width: 10),
      Expanded(
        child: TextFormField(
          controller: typeController,
          decoration: InputDecoration(labelText: 'Type'),
          keyboardType: TextInputType.multiline,
        ),
      ),
      SizedBox(width: 10),
      Expanded(
        child: TextFormField(
          controller: priceController,
          decoration: InputDecoration(labelText: 'Price'),
          keyboardType: TextInputType.multiline,
        ),
      ),
      SizedBox(width: 10),
      Expanded(
        child: TextFormField(
          controller: quantityController,
          decoration: InputDecoration(labelText: 'Quantity'),
          keyboardType: TextInputType.multiline,
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
                controller: _billDateController,
                decoration: InputDecoration(labelText: 'Bill Date'),
                keyboardType: TextInputType.multiline,
                onChanged: (_) => _updateBill(),
              ),
              TextFormField(
                controller: _billTimeController,
                decoration: InputDecoration(labelText: 'Bill Time'),
                keyboardType: TextInputType.multiline,
                onChanged: (_) => _updateBill(),
              ),
              const SizedBox(height: 16),
              Text(
                'Items',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._items.map((item) => _buildItemInput(item)).toList(),
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