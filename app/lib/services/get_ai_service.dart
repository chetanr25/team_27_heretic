import 'package:med_info/services/gen_ai_question.dart';

class GetAiQuestions {
  Future<List<Map<String, dynamic>>> getAiQuestions(String content) async {
    // final Map<String, dynamic> data = jsonDecode(response.body);
    final GenAiQuestion genAiQuestion = GenAiQuestion();
    final List<Map<String, dynamic>> questionList = await genAiQuestion
        .generateQuestions(content);
    print(questionList);
    final x =
        questionList.map((question) {
          final List<dynamic> optionsList =
              question['options'] as List<dynamic>;
          final Map<String, String> optionsMap = {};

          for (int i = 0; i < optionsList.length; i++) {
            String letter = String.fromCharCode(65 + i);
            optionsMap[letter] = optionsList[i].toString();
          }

          return {
            'question': question['question'],
            'correct_option_letter': question['correct_option_letter'],
            'correct_answer': question['correct_answer'],
            'options': optionsMap,
          };
        }).toList();
    // print(x);
    return x;
  }
}
