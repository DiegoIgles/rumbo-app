import 'package:flutter/material.dart';

import '../models/cv_review.dart';
import '../theme.dart';
import '../widgets/feedback_view.dart';
import '../widgets/ui_kit.dart';

class InterviewFeedbackScreen extends StatelessWidget {
  final CvFeedback feedback;

  const InterviewFeedbackScreen({super.key, required this.feedback});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: const Text('Recomendaciones')),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: RumboColors.ink,
          border: Border(top: BorderSide(color: RumboColors.outlineSoft)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Volver a Crecimiento'),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            FadeSlideIn(
              index: 0,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: RumboColors.brandGradient,
                  borderRadius: BorderRadius.circular(RumboRadii.xl),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '¡Terminaste la práctica!',
                      style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Practicar es la mitad del trabajo. Esto es lo que notó la IA.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13.5,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 26),
            FeedbackView(feedback: feedback, titulo: 'Cómo te fue'),
          ],
        ),
      ),
    );
  }
}
