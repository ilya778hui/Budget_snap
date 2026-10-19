import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FinanceQuizScreen extends StatefulWidget {
  const FinanceQuizScreen({super.key});

  @override
  State<FinanceQuizScreen> createState() => _FinanceQuizScreenState();
}

class _FinanceQuizScreenState extends State<FinanceQuizScreen> {
  String _difficulty = 'средний';
  List<Map<String, dynamic>> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  bool _isLoading = false;
  bool _quizStarted = false;
  bool _answered = false;
  String? _selectedAnswer;
  String? _explanation;

  Future<void> _generateQuiz() async {
    setState(() {
      _isLoading = true;
      _questions = [];
      _currentIndex = 0;
      _score = 0;
      _answered = false;
      _selectedAnswer = null;
      _quizStarted = false;
    });

    try {
      final apiKey = dotenv.env['ANTHROPIC_API_KEY'] ?? '';
      if (apiKey.isEmpty) throw Exception('API ключ не найден');

      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-sonnet-4-5',
          'max_tokens': 2048,
          'system': 'You generate finance quiz questions. Return ONLY valid JSON. No markdown, no code blocks, no apostrophes in text, no backticks. Use only double quotes for strings. Never use apostrophe character in any text value.',
          'messages': [
            {
              'role': 'user',
              'content': '''Generate 10 finance literacy questions in Russian language for teenagers in Kazakhstan. Difficulty level: $_difficulty.

STRICT RULES:
- Return ONLY the JSON object, nothing else
- No markdown, no backticks, no code blocks
- Never use apostrophe (') character anywhere in the JSON
- Never use single quotes anywhere
- Use only double quotes for JSON strings
- Keep all text simple without special punctuation
- If a word needs apostrophe, rewrite it without one

JSON format:
{"questions":[{"question":"текст вопроса","options":["вариант А","вариант Б","вариант В","вариант Г"],"correct":"вариант А","explanation":"краткое объяснение"}]}

Return ONLY the JSON, no other text.'''
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        var text = data['content'][0]['text'] as String;

        // Убираем markdown если есть
        text = text.replaceAll('```json', '').replaceAll('```', '').trim();

        // Удаляем апострофы которые ломают JSON
        text = text.replaceAll("'", '');

        // Извлекаем JSON
        final jsonStart = text.indexOf('{');
        final jsonEnd = text.lastIndexOf('}') + 1;
        if (jsonStart == -1 || jsonEnd <= jsonStart) {
          throw Exception('Неверный формат ответа от AI');
        }
        final jsonStr = text.substring(jsonStart, jsonEnd);
        final parsed = jsonDecode(jsonStr);
        final questionsRaw = parsed['questions'] as List<dynamic>;

        setState(() {
          _questions = questionsRaw
              .map((q) => Map<String, dynamic>.from(q as Map))
              .toList();
          _isLoading = false;
          _quizStarted = true;
        });
      } else {
        final error = jsonDecode(response.body);
        throw Exception('Ошибка API: ${error['error']['message']}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  void _selectAnswer(String answer) {
    if (_answered) return;
    final question = _questions[_currentIndex];
    final correct = question['correct'] as String;
    final isCorrect = answer == correct;
    setState(() {
      _selectedAnswer = answer;
      _answered = true;
      _explanation = question['explanation'] as String;
      if (isCorrect) _score++;
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _answered = false;
        _selectedAnswer = null;
        _explanation = null;
      });
    } else {
      _showResults();
    }
  }

  void _showResults() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🎉 Результат', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$_score / ${_questions.length}',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _getResultMessage(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _quizStarted = false;
                _questions = [];
              });
            },
            child: const Text('Попробовать снова'),
          ),
        ],
      ),
    );
  }

  String _getResultMessage() {
    final percent = _score / _questions.length;
    if (percent == 1.0) return '🏆 Отлично! Ты финансовый эксперт!';
    if (percent >= 0.7) return '👍 Хороший результат! Есть над чем поработать.';
    if (percent >= 0.5) return '📚 Неплохо, но стоит подтянуть знания.';
    return '💪 Не сдавайся! Попробуй ещё раз.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧠 Финансовый тест'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildLoading()
            : !_quizStarted
                ? _buildStartScreen()
                : _buildQuizScreen(),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.green),
          SizedBox(height: 16),
          Text('AI генерирует вопросы...', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildStartScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          const Text('🧠', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 16),
          const Text(
            'Финансовый тест',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'AI сгенерирует 10 вопросов по финансовой грамотности',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          const Text(
            'Уровень сложности',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['лёгкий', 'средний', 'сложный'].map((level) {
              final isSelected = _difficulty == level;
              return GestureDetector(
                onTap: () => setState(() => _difficulty = level),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.green : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    level,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _generateQuiz,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text(
              'Начать тест',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizScreen() {
    final question = _questions[_currentIndex];
    final options = List<String>.from(question['options'] as List);
    final correct = question['correct'] as String;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: (_currentIndex + 1) / _questions.length,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Вопрос ${_currentIndex + 1} из ${_questions.length}',
                          style: const TextStyle(color: Colors.grey)),
                      Text('Счёт: $_score',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      question['question'] as String,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...options.map((option) {
                    Color? color;
                    if (_answered) {
                      if (option == correct) {
                        color = Colors.green.shade100;
                      } else if (option == _selectedAnswer && option != correct) {
                        color = Colors.red.shade100;
                      }
                    }
                    return GestureDetector(
                      onTap: () => _selectAnswer(option),
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: color ?? Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _answered && option == correct
                                ? Colors.green
                                : _answered && option == _selectedAnswer && option != correct
                                    ? Colors.red
                                    : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                                child: Text(option,
                                    style: const TextStyle(fontSize: 16))),
                            if (_answered && option == correct)
                              const Icon(Icons.check_circle, color: Colors.green),
                            if (_answered && option == _selectedAnswer && option != correct)
                              const Icon(Icons.cancel, color: Colors.red),
                          ],
                        ),
                      ),
                    );
                  }),
                  if (_answered && _explanation != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('💡 Объяснение',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, color: Colors.blue)),
                          const SizedBox(height: 4),
                          Text(_explanation!, style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _nextQuestion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _currentIndex < _questions.length - 1
                            ? 'Следующий вопрос →'
                            : 'Завершить тест',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}