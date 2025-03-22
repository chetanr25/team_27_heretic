import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GenAiQuestion {
  Future<List<Map<String, dynamic>>> generateQuestions(
    String profileData,
  ) async {
    String apiKey = dotenv.env['GEMINI_API_KEY']!;
    // print(apiKey);
    try {
      // Create profile summary
      // final String profileSummary = _createProfileSummary(profileData);

      // Prepare the prompt
      final prompt = '''
        Generate 5 multiple choice questions based on this medical profile:
        $profileData
        
        Format each question as JSON with:
        - question (string)
        - correct_answer (integer index 0-3)
        - options (list of 4 strings)
        
        Return exactly 5 questions.
      ''';
      // print(prompt);
      // Initialize Gemini
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

      // Generate content
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      // Parse the response
      final responseText = response.text;
      // print(responseText);
      if (responseText == null) {
        throw Exception('No response from Gemini');
      }

      // Convert the response to JSON format
      // Assuming the response is in the correct JSON format
      final List<Map<String, dynamic>> questions = _parseGeminiResponse(
        responseText,
      );

      return questions
          .map<Map<String, dynamic>>(
            (question) => {
              'question': question['question'],
              'correct_answer': question['correct_answer'],
              'options': List<String>.from(question['options']),
            },
          )
          .toList();
    } catch (e) {
      throw Exception('Error generating questions: $e');
    }
  }

  // String _createProfileSummary(Map<String, dynamic> profileData) {
  //   final StringBuffer summary = StringBuffer();
  //   profileData.forEach((key, value) {
  //     if (value != null) {
  //       summary.writeln('$key: $value');
  //     }
  //   });
  //   return summary.toString();
  // }

  List<Map<String, dynamic>> _parseGeminiResponse(String response) {
    try {
      // Remove any markdown formatting if present
      final cleanResponse = response
          .replaceAll('```json', '')
          .replaceAll('```', '');

      // Parse the JSON response
      final parsedResponse = json.decode(cleanResponse);

      // If the response is directly an array of questions
      if (parsedResponse is List) {
        return parsedResponse.cast<Map<String, dynamic>>();
      }

      // If the response has a questions key
      if (parsedResponse is Map && parsedResponse.containsKey('questions')) {
        return parsedResponse['questions'];
      }

      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Failed to parse Gemini response: $e');
    }
  }
}
