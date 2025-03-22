import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:med_info/services/get_ai_service.dart';
// import 'package:med_info/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import 'dart:io';
// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:med_info/screens/quiz_loading_screen.dart';

class GetAllDetailsGenerateQuestions {
  Future<void> getDetails(BuildContext context) async {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => QuizLoadingScreen(questionsLoader: _loadQuestions()),
        ),
      );
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _loadQuestions() async {
    final response = await http.get(
      Uri.parse(ApiConstants.allDetailsEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization':
            'Bearer ${(await SharedPreferences.getInstance()).getString('auth_token')}',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode >= 400) {
      final errorData = json.decode(response.body);
      throw UnauthorizedException(
        message: errorData['message'],
        details: errorData['details'] ?? {},
      );
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decodedResponse = json.decode(response.body);
      final questions = await GetAiQuestions().getAiQuestions(response.body);
      return questions;
    }

    throw Exception('Unexpected response: ${response.statusCode}');
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
