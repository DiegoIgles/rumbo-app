import 'package:flutter/material.dart';

import '../models/cv_review.dart';

/// Tarjeta de feedback de IA (resumen/fortalezas/a_mejorar), reusada por la
/// revisión de CV y por el cierre de la práctica de entrevistas.
class FeedbackView extends StatelessWidget {
  final CvFeedback feedback;
  final String titulo;

  const FeedbackView({super.key, required this.feedback, this.titulo = 'Feedback'});

  @override
  Widget build(BuildContext context) {
    final f = feedback;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(f.resumen),
            if (f.fortalezas.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Fortalezas', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              ...f.fortalezas.map((s) => _BulletLine(icon: Icons.check_circle_outline, color: const Color(0xFF059669), text: s)),
            ],
            if (f.aMejorar.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('A mejorar', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              ...f.aMejorar.map((s) => _BulletLine(icon: Icons.arrow_circle_up_outlined, color: const Color(0xFFB45309), text: s)),
            ],
            if (f.notaIa != null) ...[
              const SizedBox(height: 16),
              Text(f.notaIa!, style: const TextStyle(fontSize: 12, color: Colors.black45, fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _BulletLine({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
