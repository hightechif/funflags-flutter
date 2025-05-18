import 'package:flutter/material.dart';
import 'package:funflags/presentation/screens/quiz_screen.dart';
import 'package:funflags/presentation/widgets/category_card.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learn Country Flags'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Choose a region to practice:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              CategoryCard(
                title: 'World',
                subtitle: 'All Countries',
                icon: Icons.public,
                onTap: () => _navigateToQuiz(context, 'World'),
              ),
              const SizedBox(height: 16),
              CategoryCard(
                title: 'Africa',
                subtitle: '54 Countries',
                icon: Icons.flag,
                onTap: () => _navigateToQuiz(context, 'Africa'),
              ),
              const SizedBox(height: 16),
              CategoryCard(
                title: 'Americas',
                subtitle: '35 Countries',
                icon: Icons.flag,
                onTap: () => _navigateToQuiz(context, 'Americas'),
              ),
              const SizedBox(height: 16),
              CategoryCard(
                title: 'Asia',
                subtitle: '48 Countries',
                icon: Icons.flag,
                onTap: () => _navigateToQuiz(context, 'Asia'),
              ),
              const SizedBox(height: 16),
              CategoryCard(
                title: 'Europe',
                subtitle: '44 Countries',
                icon: Icons.flag,
                onTap: () => _navigateToQuiz(context, 'Europe'),
              ),
              const SizedBox(height: 16),
              CategoryCard(
                title: 'Oceania',
                subtitle: '14 Countries',
                icon: Icons.flag,
                onTap: () => _navigateToQuiz(context, 'Oceania'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToQuiz(BuildContext context, String region) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(region: region),
      ),
    );
  }
}