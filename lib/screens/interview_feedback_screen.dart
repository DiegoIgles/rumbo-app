import 'package:flutter/material.dart';

import '../models/cv_review.dart';
import '../widgets/feedback_view.dart';

class InterviewFeedbackScreen extends StatelessWidget {
  final CvFeedback feedback;

  const InterviewFeedbackScreen({super.key, required this.feedback});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: const Text('Recomendaciones')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.emoji_events_outlined, color: Color(0xFF059669)),
                  SizedBox(width: 8),
                  Expanded(child: Text('¡Terminaste la práctica! Esto es lo que notó la IA.')),
                ],
              ),
              const SizedBox(height: 20),
              FeedbackView(feedback: feedback, titulo: 'Cómo te fue'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  child: const Text('Volver a Crecimiento'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
