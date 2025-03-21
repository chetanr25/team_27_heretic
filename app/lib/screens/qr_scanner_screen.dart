import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'dart:convert';
import '../services/patient_service.dart';
import 'patient_details_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isProcessing = false;
  final PatientService _patientService = PatientService();

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> _processQRData(String qrData) async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
    });

    try {
      // Parse QR data
      final qrJson = json.decode(qrData);
      print(qrJson);
      // if (qrJson['type'] != 'patient_id') {
      //   throw Exception('Invalid QR code type');
      // }

      // Pause the scanner
      await controller?.pauseCamera();

      // Process the scan
      final patientData = await _patientService.processQrScan(qrJson['id']);

      // Navigate to details screen
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PatientDetailsScreen(patientData: patientData),
        ),
      );

      // Resume the scanner after returning from details screen
      await controller?.resumeCamera();
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid QR Code')));
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Scanner')),
      body: Stack(
        children: [
          QRView(
            key: qrKey,
            onQRViewCreated: (QRViewController controller) {
              this.controller = controller;
              controller.scannedDataStream.listen((scanData) {
                // print('hello hello $scanData');
                if (scanData.code != null) {
                  _processQRData(scanData.code!);
                }
              });
            },
          ),
          if (isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
