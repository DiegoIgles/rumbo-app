import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/mentoria_grupal.dart';
import '../services/api_client.dart';
import '../services/auth_controller.dart';
import 'mentoria_grupal_form_screen.dart';
import 'mentoria_grupal_screen.dart' show formatearFechaHora;

class MentoriaGrupalMentorScreen extends StatefulWidget {
  const MentoriaGrupalMentorScreen({super.key});

  @override
  State<MentoriaGrupalMentorScreen> createState() => _MentoriaGrupalMentorScreenState();
}

class _MentoriaGrupalMentorScreenState extends State<MentoriaGrupalMentorScreen> {
  late Future<List<MentoriaGrupal>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<MentoriaGrupal>> _load() => context.read<AuthController>().api.misMentoriasGrupales();

  void _reload() => setState(() {
        _future = _load();
      });

  Future<void> _nuevaMentoria() async {
    final creada = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const MentoriaGrupalFormScreen()),
    );
    if (creada == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis mentorías grupales')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nuevaMentoria,
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _reload();
          await _future;
        },
        child: FutureBuilder<List<MentoriaGrupal>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 60),
                  Center(
                    child: Text(
                      snapshot.error is ApiException ? (snapshot.error as ApiException).message : 'Error al cargar tus mentorías grupales',
                    ),
                  ),
                ],
              );
            }
            final grupales = snapshot.data ?? [];
            if (grupales.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 60),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Todavía no publicaste ninguna mentoría grupal. Tocá "Nueva" para crear la primera.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: grupales.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final g = grupales[i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(g.titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 6),
                        Text(formatearFechaHora(g.fechaHora), style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
                        const SizedBox(height: 6),
                        Text('${g.inscritos}/${g.cupoMaximo} inscritos', style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => Navigator.of(context)
                                    .push(MaterialPageRoute(builder: (_) => InscritosGrupalScreen(grupal: g))),
                                icon: const Icon(Icons.people_outline, size: 16),
                                label: const Text('Ver inscritos'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => launchUrl(Uri.parse(g.meetLink), mode: LaunchMode.externalApplication),
                              icon: const Icon(Icons.videocam_outlined),
                              tooltip: 'Abrir Meet',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class InscritosGrupalScreen extends StatefulWidget {
  final MentoriaGrupal grupal;

  const InscritosGrupalScreen({super.key, required this.grupal});

  @override
  State<InscritosGrupalScreen> createState() => _InscritosGrupalScreenState();
}

class _InscritosGrupalScreenState extends State<InscritosGrupalScreen> {
  late Future<List<InscritoGrupal>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AuthController>().api.inscritosMentoriaGrupal(widget.grupal.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.grupal.titulo)),
      body: FutureBuilder<List<InscritoGrupal>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error is ApiException ? (snapshot.error as ApiException).message : 'Error al cargar los inscritos'),
            );
          }
          final inscritos = snapshot.data ?? [];
          if (inscritos.isEmpty) {
            return const Center(child: Text('Todavía no se unió nadie.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: inscritos.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final p = inscritos[i];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(p.nombre),
                subtitle: Text(p.email),
              );
            },
          );
        },
      ),
    );
  }
}
