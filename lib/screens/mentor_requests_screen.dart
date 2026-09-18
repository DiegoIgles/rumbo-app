import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/mentoria.dart';
import '../services/api_client.dart';
import '../services/auth_controller.dart';
import 'mentoria_chat_screen.dart';

class MentorRequestsScreen extends StatefulWidget {
  const MentorRequestsScreen({super.key});

  @override
  State<MentorRequestsScreen> createState() => _MentorRequestsScreenState();
}

class _MentorRequestsScreenState extends State<MentorRequestsScreen> {
  late Future<List<Mentoria>> _future;
  final Set<String> _respondiendo = {};

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Mentoria>> _load() => context.read<AuthController>().api.misMentorias();

  void _reload() => setState(() {
        _future = _load();
      });

  Future<void> _responder(Mentoria m, bool aceptar) async {
    setState(() => _respondiendo.add(m.id));
    try {
      await context.read<AuthController>().api.responderMentoria(mentoriaId: m.id, aceptar: aceptar);
      _reload();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo responder la solicitud')));
    } finally {
      if (mounted) setState(() => _respondiendo.remove(m.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitudes de mentoría')),
      body: RefreshIndicator(
        onRefresh: () async {
          _reload();
          await _future;
        },
        child: FutureBuilder<List<Mentoria>>(
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
                      snapshot.error is ApiException ? (snapshot.error as ApiException).message : 'Error al cargar solicitudes',
                    ),
                  ),
                ],
              );
            }
            final mentorias = snapshot.data ?? [];
            if (mentorias.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 60),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Todavía no recibiste solicitudes. Completá tu perfil de mentor para que los jóvenes te encuentren.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: mentorias.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final m = mentorias[i];
                final respondiendo = _respondiendo.contains(m.id);
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _EstadoBadge(estado: m.estado),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(m.jovenNombre, style: const TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                        if (m.estado == 'pendiente') ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: respondiendo ? null : () => _responder(m, false),
                                  child: const Text('Rechazar'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: respondiendo ? null : () => _responder(m, true),
                                  child: respondiendo
                                      ? const SizedBox(
                                          height: 16,
                                          width: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Text('Aceptar'),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (m.estado == 'aceptada') ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.chat_bubble_outline, size: 18),
                              label: const Text('Abrir chat'),
                              onPressed: () =>
                                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => MentoriaChatScreen(mentoria: m))),
                            ),
                          ),
                        ],
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

class _EstadoBadge extends StatelessWidget {
  final String estado;

  const _EstadoBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late Color fg;
    late IconData icon;
    switch (estado) {
      case 'aceptada':
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF059669);
        icon = Icons.check;
        break;
      case 'rechazada':
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFDC2626);
        icon = Icons.close;
        break;
      default:
        bg = const Color(0xFFFFFBEB);
        fg = const Color(0xFFB45309);
        icon = Icons.hourglass_empty;
    }
    return CircleAvatar(radius: 16, backgroundColor: bg, child: Icon(icon, color: fg, size: 16));
  }
}
