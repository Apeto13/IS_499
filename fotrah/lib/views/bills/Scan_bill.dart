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

  bool isNavigating = false;

  void _onQRViewCreated(QRViewController controller) async {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (!isNavigating) {
        isNavigating = true;
        final String scannedData = scanData.code ?? "";
        final String decodedData = utf8.decode(base64.decode(scannedData));
        print("Encoded: $scannedData, Decoded: $decodedData");

        final RegExp regex = RegExp(
            r'^\x01\x0F(.*?)\x02\x0F(.*?)\x03\x14(.*?)\x04\x06(.*?)\x05\x05(.*?)$');

        final Match? match = regex.firstMatch(decodedData);
        if (match != null && match.groupCount >= 4) {
          final String storeName = match.group(1)!;
          final String date = match.group(3)!;
          final String total = match.group(4)!;
          Navigator.of(context).pushNamed(
            BillDetailRoute,
            arguments: {
              'storeName': storeName,
              'date': date,
              'total': total,
            },
          );
          Future.delayed(Duration(seconds: 1), () {
            isNavigating = false;
          });
        } else {
          print('Invalid QR code format');
        }
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
