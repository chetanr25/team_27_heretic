import 'package:flutter/material.dart';
import 'package:med_info/screens/quiz_result_screen.dart';

class QuizScreen extends StatefulWidget {
  final List<Map<String, dynamic>> questions;

  const QuizScreen({super.key, required this.questions});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentQuestionIndex = 0;
  List<int?> userAnswers = [];
  bool isAnswered = false;

  @override
  void initState() {
    super.initState();
    userAnswers = List.filled(widget.questions.length, null);
  }

  void _handleAnswer(int selectedAnswer) {
    if (!isAnswered) {
      setState(() {
        userAnswers[currentQuestionIndex] = selectedAnswer;
        isAnswered = true;
      });

      // Wait for a moment to show the correct/wrong answer
      Future.delayed(const Duration(seconds: 1), () {
        if (currentQuestionIndex < widget.questions.length - 1) {
          setState(() {
            currentQuestionIndex++;
            isAnswered = false;
          });
        } else {
          // Navigate to results screen
          final score =
              userAnswers.asMap().entries.where((entry) {
                return entry.value ==
                    widget.questions[entry.key]['correct_answer'];
              }).length;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => QuizResultScreen(
                    score: score,
                    totalQuestions: widget.questions.length,
                    questions: widget.questions,
                    userAnswers: userAnswers,
                  ),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[currentQuestionIndex];
    final options = question['options'] as Map<String, String>;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade100, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearProgressIndicator(
                  value: (currentQuestionIndex + 1) / widget.questions.length,
                  backgroundColor: Colors.blue.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.blue.shade500,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Question ${currentQuestionIndex + 1}/${widget.questions.length}',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      question['question'],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ...options.entries.map((entry) {
                  final index = ['A', 'B', 'C', 'D'].indexOf(entry.key);
                  final isSelected = userAnswers[currentQuestionIndex] == index;
                  final isCorrect =
                      isAnswered && index == question['correct_answer'];

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      child: ElevatedButton(
                        onPressed: () => _handleAnswer(index),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(20),
                          backgroundColor:
                              isAnswered
                                  ? isCorrect
                                      ? Colors.green.shade100
                                      : isSelected
                                      ? Colors.red.shade100
                                      : Colors.white
                                  : Colors.white,
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: isSelected ? 8 : 4,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  entry.key,
                                  style: TextStyle(
                                    color: Colors.blue.shade900,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
