import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_controller.dart';
import '../theme.dart';
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
        icon: Icons.description_outlined,
        titulo: 'Revisión de CV con IA',
        subtitulo: 'Subí tu CV o pitch y recibí feedback al instante.',
        builder: (_) => const CvScreen(),
      ),
      _MenuItem(
        icon: Icons.forum_outlined,
        titulo: 'Práctica de entrevistas',
        subtitulo: 'Simulá una entrevista o negociación con un cliente.',
        builder: (_) => const InterviewScreen(),
      ),
      _MenuItem(
        icon: Icons.emoji_events_outlined,
        titulo: 'Insignias',
        subtitulo: 'Mirá los logros que fuiste desbloqueando.',
        builder: (_) => const BadgesScreen(),
      ),
      if (esMentor) ...[
        _MenuItem(
          icon: Icons.badge_outlined,
          titulo: 'Mi perfil de mentor',
          subtitulo: 'Contá tu área de expertise y disponibilidad para que te encuentren.',
          builder: (_) => const MentorProfileScreen(),
        ),
        _MenuItem(
          icon: Icons.inbox_outlined,
          titulo: 'Solicitudes de mentoría',
          subtitulo: 'Revisá los pedidos que te llegaron y chateá con quien aceptes.',
          builder: (_) => const MentorRequestsScreen(),
        ),
        _MenuItem(
          icon: Icons.groups_outlined,
          titulo: 'Mentoría grupal',
          subtitulo: 'Publicá sesiones grupales con cupo limitado y link de Meet.',
          builder: (_) => const MentoriaGrupalMentorScreen(),
        ),
      ] else ...[
        _MenuItem(
          icon: Icons.people_outline,
          titulo: 'Mentoría',
          subtitulo: 'Conectá con mentores y pedí acompañamiento.',
          builder: (_) => const MentoringScreen(),
        ),
        _MenuItem(
          icon: Icons.groups_outlined,
          titulo: 'Mentoría grupal',
          subtitulo: 'Unite a sesiones grupales en vivo con cupo limitado.',
          builder: (_) => const MentoriaGrupalScreen(),
        ),
      ],
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Crecimiento')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final item = items[i];
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: CircleAvatar(
                backgroundColor: rumboPrimary.withValues(alpha: 0.12),
                child: Icon(item.icon, color: rumboPrimary),
              ),
              title: Text(item.titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(item.subtitulo),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: item.builder)),
            ),
          );
        },
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String titulo;
  final String subtitulo;
  final WidgetBuilder builder;

  _MenuItem({required this.icon, required this.titulo, required this.subtitulo, required this.builder});
}
