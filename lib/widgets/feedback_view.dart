import 'package:flutter/material.dart';

import '../models/cv_review.dart';
import '../theme.dart';
import 'ui_kit.dart';

/// Tarjeta de feedback de IA (resumen / fortalezas / a mejorar). La comparten
/// la revisión de CV y el cierre de la práctica de entrevistas.
class FeedbackView extends StatelessWidget {
  final CvFeedback feedback;
  final String titulo;

  const FeedbackView({super.key, required this.feedback, this.titulo = 'Feedback'});

  @override
  Widget build(BuildContext context) {
    final f = feedback;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeSlideIn(
          index: 0,
          child: RumboCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        gradient: RumboColors.brandGradient,
                        borderRadius: BorderRadius.circular(RumboRadii.sm),
                      ),
                      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 17),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(titulo, style: Theme.of(context).textTheme.titleMedium),
                    ),
                  ],
                ),
                if (f.resumen.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    f.resumen,
                    style: const TextStyle(color: RumboColors.textMid, fontSize: 14.5, height: 1.6),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (f.fortalezas.isNotEmpty) ...[
          const SizedBox(height: 14),
          FadeSlideIn(
            index: 1,
            child: _BloqueLista(
              titulo: 'Fortalezas',
              icono: Icons.check_circle_outline_rounded,
              color: RumboColors.success,
              items: f.fortalezas,
            ),
          ),
        ],
        if (f.aMejorar.isNotEmpty) ...[
          const SizedBox(height: 14),
          FadeSlideIn(
            index: 2,
            child: _BloqueLista(
              titulo: 'A mejorar',
              icono: Icons.trending_up_rounded,
              color: RumboColors.warning,
              items: f.aMejorar,
            ),
          ),
        ],
        if (f.notaIa != null && f.notaIa!.isNotEmpty) ...[
          const SizedBox(height: 16),
          FadeSlideIn(
            index: 3,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, size: 13, color: RumboColors.textLow),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    f.notaIa!,
                    style: const TextStyle(
                      color: RumboColors.textLow,
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _BloqueLista extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Color color;
  final List<String> items;

  const _BloqueLista({
    required this.titulo,
    required this.icono,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return RumboCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 17, color: color),
              const SizedBox(width: 9),
              Text(
                titulo,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color),
              ),
              const Spacer(),
              Text(
                '${items.length}',
                style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 11),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 7, right: 11),
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                Expanded(
                  child: Text(
                    items[i],
                    style: const TextStyle(color: RumboColors.textMid, fontSize: 14, height: 1.5),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
