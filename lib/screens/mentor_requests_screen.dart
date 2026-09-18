import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/mentoria.dart';
import '../services/api_client.dart';
import '../services/auth_controller.dart';
import '../theme.dart';
import '../utils/formato.dart';
import '../widgets/ui_kit.dart';
import 'mentoria_chat_screen.dart';
import 'mentoring_screen.dart' show EstadoMentoriaIcono;

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo responder la solicitud')),
        );
      }
    } finally {
      if (mounted) setState(() => _respondiendo.remove(m.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitudes')),
      body: SafeArea(
        top: false,
        child: RumboRefresh(
          onRefresh: () async {
            _reload();
            await _future.catchError((_) => <Mentoria>[]);
          },
          child: FutureBuilder<List<Mentoria>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SkeletonList(cantidad: 3);
              }
              if (snapshot.hasError) {
                final msg = snapshot.error is ApiException
                    ? (snapshot.error as ApiException).message
                    : 'No pudimos cargar las solicitudes';
                return ScrollableStatusView(
                  view: StatusView(
                    icono: Icons.cloud_off_rounded,
                    titulo: 'No se pudo conectar',
                    detalle: msg,
                    textoAccion: 'Reintentar',
                    onAccion: _reload,
                    esError: true,
                  ),
                );
              }
              final mentorias = snapshot.data ?? [];
              if (mentorias.isEmpty) {
                return const ScrollableStatusView(
                  view: StatusView(
                    icono: Icons.inbox_outlined,
                    titulo: 'Sin solicitudes todavía',
                    detalle: 'Completá tu perfil de mentor para que los jóvenes te encuentren.',
                  ),
                );
              }

              // Las pendientes primero: son las únicas que piden una acción.
              final ordenadas = [...mentorias]..sort((a, b) {
                  if (a.estado == b.estado) return 0;
                  if (a.estado == 'pendiente') return -1;
                  if (b.estado == 'pendiente') return 1;
                  return 0;
                });
              final pendientes = ordenadas.where((m) => m.estado == 'pendiente').length;

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                itemCount: ordenadas.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        pendientes == 0
                            ? 'No tenés solicitudes pendientes'
                            : pendientes == 1
                                ? '1 solicitud esperando tu respuesta'
                                : '$pendientes solicitudes esperando tu respuesta',
                        style: const TextStyle(color: RumboColors.textLow, fontSize: 12.5),
                      ),
                    );
                  }
                  final m = ordenadas[i - 1];
                  return FadeSlideIn(
                    key: ValueKey(m.id),
                    index: i - 1,
                    child: _SolicitudCard(
                      mentoria: m,
                      respondiendo: _respondiendo.contains(m.id),
                      onResponder: (aceptar) => _responder(m, aceptar),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SolicitudCard extends StatelessWidget {
  final Mentoria mentoria;
  final bool respondiendo;
  final ValueChanged<bool> onResponder;

  const _SolicitudCard({
    required this.mentoria,
    required this.respondiendo,
    required this.onResponder,
  });

  @override
  Widget build(BuildContext context) {
    final m = mentoria;
    final pendiente = m.estado == 'pendiente';

    return RumboCard(
      padding: const EdgeInsets.all(15),
      borderColor: pendiente ? RumboColors.warning.withValues(alpha: 0.3) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              EstadoMentoriaIcono(estado: m.estado),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.jovenNombre, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    MetaRow(
                      icono: Icons.schedule_rounded,
                      texto: 'Solicitó ${haceCuantoIso(m.fechaSolicitud)}',
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (pendiente) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: respondiendo ? null : () => onResponder(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: RumboColors.danger,
                      side: BorderSide(color: RumboColors.danger.withValues(alpha: 0.4)),
                    ),
                    child: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: respondiendo ? null : () => onResponder(true),
                    child: respondiendo
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                          )
                        : const Text('Aceptar'),
                  ),
                ),
              ],
            ),
          ],
          if (m.estado == 'aceptada') ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 17),
                label: const Text('Abrir chat'),
                onPressed: () => Navigator.of(context).push(
                  RumboPageRoute(builder: (_) => MentoriaChatScreen(mentoria: m)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
