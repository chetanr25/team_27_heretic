import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
// import 'package:med_info/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      final requestBody = {'patientId': patientId};

      print('Making request to: ${ApiConstants.scanQrEndpoint}');
      print('Request body: ${json.encode(requestBody)}');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final role = prefs.getString('role');
      print('Role: $role');
      final url =
          role == 'patient'
              ? ApiConstants.patientScanQrEndpoint
              : ApiConstants.scanQrEndpoint;
      // final token =
      //     "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI2N2RkNjkwY2U1NDRlOTlkZjQ3NGM1YmIiLCJpYXQiOjE3NDI1NzIxNjksImV4cCI6MTc0MjY1ODU2OX0.vjOeIaHUeXlTyCOCLhZ9FBe0vS5lmTYOJx5owHsIATM";
      // SharedPreferences.getInstance().then((prefs) {
      //   final role = prefs.getString('role');
      //   print('Role: $role');
      //   false // role != 'patient'
      //       ? ApiConstants.scanQrEndpoint
      //       : ApiConstants.patientScanQrEndpoint;
      // });
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      // First check for 403 status
      if (response.statusCode >= 400) {
        final errorData = json.decode(response.body);
        throw UnauthorizedException(
          message: errorData['message'],
          details: errorData['details'] ?? {},
        );
      }

      // Then check for other error status codes
      if (response.statusCode >= 400) {
        throw HttpException(
          'Server error ${response.statusCode}: ${response.body}',
        );
      }

      // Finally handle success cases
      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedResponse = json.decode(response.body);
        return decodedResponse;
      }

      throw Exception('Unexpected response: ${response.statusCode}');
    } catch (e) {
      print('Error: $e');
      rethrow;
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

class UnauthorizedException implements Exception {
  final String message;
  final Map<String, dynamic> details;

  UnauthorizedException({required this.message, required this.details});
}
