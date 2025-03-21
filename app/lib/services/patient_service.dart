import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class PatientService {
  Future<Map<String, dynamic>> processQrScan(String patientId) async {
    // For development only - bypass certificate validation
    if (kDebugMode) {
      HttpOverrides.global = _DevHttpOverrides();
    }

    try {
      final requestBody = {
        'patientId': "67dd688de544e99df474c59f", // patientId,
      };

      print('Making request to: ${ApiConstants.scanQrEndpoint}');
      print('Request body: ${json.encode(requestBody)}');

      final token =
          "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI2N2RkNjkwY2U1NDRlOTlkZjQ3NGM1YmIiLCJpYXQiOjE3NDI1NzIxNjksImV4cCI6MTc0MjY1ODU2OX0.vjOeIaHUeXlTyCOCLhZ9FBe0vS5lmTYOJx5owHsIATM";

      final response = await http
          .post(
            Uri.parse(ApiConstants.scanQrEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
            body: json.encode(requestBody),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Request timed out');
            },
          );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode >= 400) {
        throw HttpException(
          'Server error ${response.statusCode}: ${response.body}',
        );
      }

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        print('Decoded response: $decodedResponse');
        return decodedResponse;
      }

      throw Exception('Unexpected response: ${response.statusCode}');
    } catch (e, stackTrace) {
      print('Error in processQrScan: $e');
      print('Stack trace: $stackTrace');

      // For development, rethrow to see the error in the debugger
      rethrow;

      // In production, return dummy data
      // return _getDummyPatientData();
    }
  }

  // Map<String, dynamic> _getDummyPatientData() {
  //   return {
  //     'patientName': 'John Doe',
  //     'age': 45,
  //     'lastVisit': '2024-03-15',
  //     'diagnosis': 'Common Cold',
  //   };
  // }
}

class _DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}
