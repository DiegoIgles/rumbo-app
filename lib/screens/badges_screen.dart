import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/badge.dart';
import '../services/api_client.dart';
import '../services/auth_controller.dart';
import '../theme.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  late Future<List<AppBadge>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AuthController>().api.badges();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Insignias')),
      body: FutureBuilder<List<AppBadge>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error is ApiException ? (snapshot.error as ApiException).message : 'Error al cargar insignias'),
            );
          }
          final badges = snapshot.data ?? [];
          if (badges.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Todavía no desbloqueaste insignias. Hacé check-ins, revisá tu CV o practicá una entrevista para ganar la primera.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: badges.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final b = badges[i];
              final info = infoBadge(b.tipo);
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    backgroundColor: rumboPrimary.withValues(alpha: 0.12),
                    child: const Icon(Icons.emoji_events, color: rumboPrimary),
                  ),
                  title: Text(info.titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(info.descripcion),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
