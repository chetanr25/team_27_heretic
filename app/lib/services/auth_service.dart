import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

class AuthService {
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  Future<Map<String, dynamic>> signup(Map<String, dynamic> userData) async {
    try {
      print('Making request to: ${ApiConstants.registerEndpoint}');
      print('Request body: ${json.encode(userData)}');
      final response = await http.post(
        Uri.parse(ApiConstants.registerEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userData),
      );
      print(response.body);
      print(response.statusCode);
      final responseData = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Store token and user data in SharedPreferences
        await _saveAuthData(responseData['token'], responseData['user']);

        return responseData;
      } else if (response.statusCode == 400 || response.statusCode == 403) {
        return responseData;
        throw Exception('Registration failed: ${response.body}');
      } else {
        throw Exception('Registration failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  Future<void> _saveAuthData(
    String token,
    Map<String, dynamic> userData,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
    await prefs.setString(userKey, json.encode(userData));
    await prefs.setString('role', userData['role']);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey) != null;
  }

  Future<Map<String, dynamic>> login(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.loginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userData),
      );
      print(response.body);
      print(response.statusCode);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Store token and user data in SharedPreferences
        await _saveAuthData(responseData['token'], responseData['user']);

        return responseData;
      } else {
        throw Exception('Login failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }
}
