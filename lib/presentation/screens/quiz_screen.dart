import 'dart:math';

import 'package:flutter/material.dart';
import 'package:funflags/data/services/country_service.dart';
import 'package:funflags/domain/models/country.dart';

class QuizScreen extends StatefulWidget {
  final String region;

  const QuizScreen({super.key, required this.region});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  bool _isLoading = true;
  List<Country> _countries = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _answered = false;
  int? _selectedAnswerIndex;
  List<int> _optionIndices = [];

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    try {
      if (widget.region == 'World') {
        _countries = await CountryService.getAllCountries();
      } else {
        _countries = await CountryService.getCountriesByRegion(widget.region);
      }

      _countries.shuffle();
      _prepareQuestion();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {{
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading countries: $e')));
      }}
    }
  }

  void _prepareQuestion() {
    final random = Random();
    _optionIndices = [];

    // Add correct answer
    _optionIndices.add(_currentQuestionIndex);

    // Add 3 wrong answers
    while (_optionIndices.length < 4) {
      int randomIndex = random.nextInt(_countries.length);
      if (!_optionIndices.contains(randomIndex)) {
        _optionIndices.add(randomIndex);
      }
    }

    // Shuffle options
    _optionIndices.shuffle();
  }

  void _checkAnswer(int optionIndex) {
    if (_answered) return;

    setState(() {
      _answered = true;
      _selectedAnswerIndex = optionIndex;

      if (_countries[_optionIndices[optionIndex]].name ==
          _countries[_currentQuestionIndex].name) {
        _score++;
      }
    });

    // Wait for 1.5 seconds before moving to next question
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (_currentQuestionIndex < _countries.length - 1) {
        setState(() {
          _currentQuestionIndex++;
          _answered = false;
          _selectedAnswerIndex = null;
          _prepareQuestion();
        });
      } else {
        // Quiz completed
        _showQuizCompletedDialog();
      }
    });
  }

  void _showQuizCompletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Quiz Completed!'),
            content: Text(
              'Your score: $_score out of ${_countries.length}',
              style: const TextStyle(fontSize: 18),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to learn screen
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.region} Flags Quiz')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      LinearProgressIndicator(
                        value: (_currentQuestionIndex + 1) / _countries.length,
                        backgroundColor: Colors.grey[300],
                        color: Theme.of(context).primaryColor,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Question ${_currentQuestionIndex + 1} of ${_countries.length}',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 160,
                        width: 320,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Image.network(
                            _countries[_currentQuestionIndex].flagUrl,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Text('Failed to load flag image'),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Which country does this flag belong to?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ...List.generate(4, (index) {
                        bool isCorrect =
                            _countries[_optionIndices[index]].name ==
                            _countries[_currentQuestionIndex].name;
                        bool isSelected = _selectedAnswerIndex == index;

                        Color? backgroundColor;
                        if (_answered) {
                          if (isCorrect) {
                            backgroundColor = Colors.green[100];
                          } else if (isSelected) {
                            backgroundColor = Colors.red[100];
                          }
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: ElevatedButton(
                            onPressed:
                                _answered ? null : () => _checkAnswer(index),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: backgroundColor,
                              foregroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color:
                                      _answered && isCorrect
                                          ? Colors.green
                                          : _answered && isSelected
                                          ? Colors.red
                                          : Colors.grey.shade300,
                                  width:
                                      _answered && (isCorrect || isSelected)
                                          ? 2
                                          : 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _countries[_optionIndices[index]].name,
                                    style: const TextStyle(fontSize: 16),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                if (_answered)
                                  Icon(
                                    isCorrect
                                        ? Icons.check_circle
                                        : (isSelected ? Icons.cancel : null),
                                    color: isCorrect ? Colors.green : Colors.red,
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
    );
  }
}
