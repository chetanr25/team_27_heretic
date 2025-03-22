import 'package:flutter/material.dart';
import 'package:med_info/services/all_details.dart'
    show AllDetails, GetAllDetailsGenerateQuestions;
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'dart:convert';
import '../services/patient_service.dart';
import 'patient_details_screen.dart';
import 'access_denied_screen.dart';

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

  Future<void> _handleScan(String scanData) async {
    print('Scan data: $scanData');
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
    });

    try {
      // Pause camera while processing
      await controller?.pauseCamera();

      final id = jsonDecode(scanData)['id'];
      final patientData = await _patientService.processQrScan(id);
      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PatientDetailsScreen(patientData: patientData),
        ),
      );
    } on UnauthorizedException catch (e) {
      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  AccessDeniedScreen(message: e.message, details: e.details),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        isProcessing = false;
      });
    } finally {
      // Resume camera and reset processing state
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
        await controller?.resumeCamera();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Scanner'),
        actions: [
          IconButton(
            onPressed: () {
              GetAllDetailsGenerateQuestions().getDetails(context);
            },
            icon: const Icon(Icons.emoji_events),
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Stack(
        children: [
          QRView(
            key: qrKey,
            onQRViewCreated: (QRViewController controller) {
              this.controller = controller;
              controller.scannedDataStream.listen((scanData) {
                if (scanData.code != null) {
                  _handleScan(scanData.code!);
                }
              });
            },
          ),
          if (isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
