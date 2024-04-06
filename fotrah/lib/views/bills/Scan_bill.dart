import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fotrah/constants/routes.dart';
import 'package:fotrah/services/cloud/cloud_bill.dart';
import 'package:intl/intl.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';

class ScanBillPageState extends StatefulWidget {
  const ScanBillPageState({super.key});

  @override
  State<ScanBillPageState> createState() => _ScanBillPageStateState();
}

class _ScanBillPageStateState extends State<ScanBillPageState> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  Barcode? result;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Scan Bill",
          style: TextStyle(
            fontSize: 25.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        elevation: 10,
        shadowColor: Colors.blueAccent.shade100,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.blueAccent.shade700],
              begin: Alignment.bottomRight,
              end: Alignment.topLeft,
            ),
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: (result != null)
                  ? Text(
                      'Barcode Type: ${describeEnum(result!.format)}   Data: ${result!.code}')
                  : Text('Scan a code'),
            ),
          )
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) async {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      print("Scan attempt detected");

      final String scannedData = scanData.code ?? "";
      final String decodedData = utf8.decode(base64.decode(scannedData));
      print("Encoded: $scannedData, Decoded: $decodedData");

      // Adjusted RegExp to loosely match date and total based on their unique formats
      final RegExp regex = RegExp(
          r'(.*?)(\d{4}-\d{1,2}-\d{1,2}T\d{1,2}:\d{2}:\d{2})Z.*?(\d+\.\d+)');

      final Match? match = regex.firstMatch(decodedData);
      // print("(1) ");
      //print(match!.group(1));
      //print("(2) ");
      //print(match!.group(2));
      //print("(3) ");
      //print(match!.group(3));
      if (match != null) {
        final String storeName = match.group(1)!.trim();
        // Original date string from the regex match
        String dateString = match.group(2)!;

        // Function to ensure two digits
        String formatTwoDigits(int n) => n.toString().padLeft(2, '0');

        // Split the date string to components
        List<String> dateParts = dateString.split('-');
        List<String> timeParts = dateParts[2].split('T')[1].split(':');

        // Ensure month, day, hour, and minute are two digits
        String month = formatTwoDigits(int.parse(dateParts[1]));
        String day = formatTwoDigits(int.parse(dateParts[2].split('T')[0]));
        String hour = formatTwoDigits(int.parse(timeParts[0]));
        String minute = timeParts[1];
        String second = timeParts[2];

        // Reconstruct the date string in ISO 8601 format
        String formattedDateStr =
            "${dateParts[0]}-$month-$day" + "T$hour:$minute:$second";

        // Now you can safely parse the date
        DateTime date = DateTime.parse(formattedDateStr);
        final String total = match.group(3)!;
        print("(1) ");
        print("$storeName, $formattedDateStr, $total");
        print("(2) ");
        print("$storeName, $date, $total");
        Navigator.of(context).pushNamed(
          BillDetailRoute,
          arguments: {
            'storeName': storeName,
            'date': date,
            'total': total,
          },
        );
      } else {
        print('Invalid QR code format');
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
