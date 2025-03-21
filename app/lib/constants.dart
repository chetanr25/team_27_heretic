class ApiConstants {
  static const String baseUrl =
      'https://ab94-2401-4900-61c0-b989-511a-3182-4a84-1cdc.ngrok-free.app';
  static const String scanQrEndpoint = '$baseUrl/api/medical/scan';
  static const String registerEndpoint = '$baseUrl/api/auth/register';
  static const String loginEndpoint = '$baseUrl/api/auth/login';

  // Hardcoded role for now
  static const String userRole = 'doctor';
}
