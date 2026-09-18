import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_controller.dart';
import '../theme.dart';
import '../widgets/ui_kit.dart';
import 'badges_screen.dart';
import 'cv_screen.dart';
import 'interview_screen.dart';
import 'mentor_profile_screen.dart';
import 'mentor_requests_screen.dart';
import 'mentoria_grupal_mentor_screen.dart';
import 'mentoria_grupal_screen.dart';
import 'mentoring_screen.dart';

class CrecimientoTab extends StatelessWidget {
  const CrecimientoTab({super.key});

  @override
  Widget build(BuildContext context) {
    final esMentor = context.watch<AuthController>().role == 'mentor';

    final items = <_MenuItem>[
      _MenuItem(
        icono: Icons.description_outlined,
        titulo: 'Revisión de CV con IA',
        subtitulo: 'Subí tu CV o pitch y recibí feedback al instante.',
        color: RumboColors.crimsonBright,
        builder: (_) => const CvScreen(),
      ),
      _MenuItem(
        icono: Icons.videocam_outlined,
        titulo: 'Práctica de entrevistas',
        subtitulo: 'Simulá una entrevista o una negociación con un cliente.',
        color: RumboColors.navyBright,
        destacado: true,
        builder: (_) => const InterviewScreen(),
      ),
      _MenuItem(
        icono: Icons.emoji_events_outlined,
        titulo: 'Insignias',
        subtitulo: 'Mirá los logros que fuiste desbloqueando.',
        color: RumboColors.warning,
        builder: (_) => const BadgesScreen(),
      ),
      if (esMentor) ...[
        _MenuItem(
          icono: Icons.badge_outlined,
          titulo: 'Mi perfil de mentor',
          subtitulo: 'Contá tu expertise y disponibilidad para que te encuentren.',
          color: RumboColors.success,
          builder: (_) => const MentorProfileScreen(),
        ),
        _MenuItem(
          icono: Icons.inbox_outlined,
          titulo: 'Solicitudes de mentoría',
          subtitulo: 'Revisá los pedidos que te llegaron y chateá con quien aceptes.',
          color: RumboColors.crimsonBright,
          builder: (_) => const MentorRequestsScreen(),
        ),
        _MenuItem(
          icono: Icons.groups_outlined,
          titulo: 'Mentoría grupal',
          subtitulo: 'Publicá sesiones grupales con cupo y link de Meet.',
          color: RumboColors.navyBright,
          builder: (_) => const MentoriaGrupalMentorScreen(),
        ),
      ] else ...[
        _MenuItem(
          icono: Icons.people_outline,
          titulo: 'Mentoría',
          subtitulo: 'Conectá con mentores y pedí acompañamiento.',
          color: RumboColors.success,
          builder: (_) => const MentoringScreen(),
        ),
        _MenuItem(
          icono: Icons.groups_outlined,
          titulo: 'Mentoría grupal',
          subtitulo: 'Unite a sesiones grupales en vivo con cupo limitado.',
          color: RumboColors.navyBright,
          builder: (_) => const MentoriaGrupalScreen(),
        ),
      ],
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
          children: [
            FadeSlideIn(
              index: 0,
              child: BrandHeader(
                icono: Icons.rocket_launch_outlined,
                titulo: 'Crecimiento',
                subtitulo: esMentor
                    ? 'Tus herramientas para acompañar a quienes empiezan.'
                    : 'Practicá, mejorá tu CV y conseguí acompañamiento.',
              ),
            ),
            const SizedBox(height: 22),
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              FadeSlideIn(index: i + 1, child: _TarjetaMenu(item: items[i])),
            ],
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final Color color;
  final WidgetBuilder builder;

  /// La tarjeta destacada usa el degradado de marca en vez del fondo plano:
  /// es la acción que más queremos que la gente pruebe.
  final bool destacado;

  _MenuItem({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.color,
    required this.builder,
    this.destacado = false,
  });
}

class _TarjetaMenu extends StatelessWidget {
  final _MenuItem item;

  const _TarjetaMenu({required this.item});

  @override
  Widget build(BuildContext context) {
    void onTap() => Navigator.of(context).push(RumboPageRoute(builder: item.builder));

    if (item.destacado) {
      return PressableScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: RumboColors.brandGradient,
            borderRadius: RumboRadii.card,
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(RumboRadii.md),
                ),
                child: Icon(item.icono, color: Colors.white, size: 23),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.titulo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitulo,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12.8,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white70),
            ],
          ),
        ),
      );
    }

    return RumboCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(RumboRadii.md),
            ),
            child: Icon(item.icono, color: item.color, size: 21),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.titulo, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 3),
                Text(
                  item.subtitulo,
                  style: const TextStyle(color: RumboColors.textLow, fontSize: 12.8, height: 1.4),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: RumboColors.textLow),
        ],
      ),
    );
  }
}
