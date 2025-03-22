class ApiConstants {
  static const String baseUrl =
      'https://0bf0-2401-4900-9010-7b9c-5d6-381d-b784-c529.ngrok-free.app';
  static const String scanQrEndpoint = '$baseUrl/api/medical/scan';
  static const String patientScanQrEndpoint =
      '$baseUrl/api/medical/patient-scan';
  static const String registerEndpoint = '$baseUrl/api/auth/register';
  static const String loginEndpoint = '$baseUrl/api/auth/login';
  static const String allDetailsEndpoint = '$baseUrl/api/medical/patient-data';

  // Hardcoded role for now
  static const String userRole = 'doctor';
}
