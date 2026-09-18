import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_constants.dart';
import '../models/mentoria.dart';
import '../services/api_client.dart';
import '../services/auth_controller.dart';
import '../theme.dart';
import '../utils/formato.dart';
import '../widgets/ui_kit.dart';
import 'mentoria_chat_screen.dart';

class MentoringScreen extends StatefulWidget {
  const MentoringScreen({super.key});

  @override
  State<MentoringScreen> createState() => _MentoringScreenState();
}

class _MentoringScreenState extends State<MentoringScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mentoría'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Mentores'), Tab(text: 'Mis mentorías')],
        ),
      ),
      body: SafeArea(
        top: false,
        child: TabBarView(
          controller: _tabController,
          children: const [_MentoresTab(), _MisMentoriasTab()],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Buscar mentores
// ---------------------------------------------------------------------------

class _MentoresTab extends StatefulWidget {
  const _MentoresTab();

  @override
  State<_MentoresTab> createState() => _MentoresTabState();
}

class _MentoresTabState extends State<_MentoresTab> {
  String? _area;
  late Future<List<MentorProfile>> _future;
  final Set<String> _solicitando = {};
  final Set<String> _solicitados = {};

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<MentorProfile>> _load() => context.read<AuthController>().api.mentores(area: _area);

  void _reload() => setState(() {
        _future = _load();
      });

  Future<void> _solicitar(MentorProfile mentor) async {
    setState(() => _solicitando.add(mentor.userId));
    try {
      await context.read<AuthController>().api.solicitarMentoria(mentorId: mentor.userId);
      if (!mounted) return;
      setState(() => _solicitados.add(mentor.userId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Le pediste mentoría a ${mentor.nombre}.')),
      );
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo enviar la solicitud')),
        );
      }
    } finally {
      if (mounted) setState(() => _solicitando.remove(mentor.userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _ChipArea(texto: 'Todas', activo: _area == null, onTap: () {
                _area = null;
                _reload();
              }),
              for (final a in areas)
                _ChipArea(
                  texto: a,
                  activo: _area == a,
                  onTap: () {
                    _area = _area == a ? null : a;
                    _reload();
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: RumboRefresh(
            onRefresh: () async {
              _reload();
              await _future.catchError((_) => <MentorProfile>[]);
            },
            child: FutureBuilder<List<MentorProfile>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SkeletonList(cantidad: 3);
                }
                if (snapshot.hasError) {
                  final msg = snapshot.error is ApiException
                      ? (snapshot.error as ApiException).message
                      : 'No pudimos cargar los mentores';
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
                final mentores = snapshot.data ?? [];
                if (mentores.isEmpty) {
                  return const ScrollableStatusView(
                    view: StatusView(
                      icono: Icons.people_outline,
                      titulo: 'Sin mentores por ahora',
                      detalle: 'Todavía no hay mentores publicados en esta área.',
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                  itemCount: mentores.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final m = mentores[i];
                    return FadeSlideIn(
                      key: ValueKey(m.userId),
                      index: i,
                      child: _MentorCard(
                        mentor: m,
                        solicitado: _solicitados.contains(m.userId),
                        solicitando: _solicitando.contains(m.userId),
                        onSolicitar: () => _solicitar(m),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ChipArea extends StatelessWidget {
  final String texto;
  final bool activo;
  final VoidCallback onTap;

  const _ChipArea({required this.texto, required this.activo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: RumboMotion.fast,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
          decoration: BoxDecoration(
            color: activo ? RumboColors.crimson : RumboColors.surface,
            borderRadius: RumboRadii.pill,
            border: Border.all(color: activo ? RumboColors.crimson : RumboColors.outline),
          ),
          child: Text(
            texto,
            style: TextStyle(
              color: activo ? Colors.white : RumboColors.textMid,
              fontSize: 12.5,
              fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _MentorCard extends StatelessWidget {
  final MentorProfile mentor;
  final bool solicitado;
  final bool solicitando;
  final VoidCallback onSolicitar;

  const _MentorCard({
    required this.mentor,
    required this.solicitado,
    required this.solicitando,
    required this.onSolicitar,
  });

  String get _iniciales {
    final partes = mentor.nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return (partes.first.substring(0, 1) + partes[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return RumboCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  gradient: RumboColors.navyGradient,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _iniciales,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mentor.nombre, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 5),
                    RumboTag(texto: mentor.areaExpertise, color: RumboColors.navyBright),
                  ],
                ),
              ),
            ],
          ),
          if (mentor.bio != null && mentor.bio!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              mentor.bio!,
              style: const TextStyle(color: RumboColors.textMid, fontSize: 13.5, height: 1.5),
            ),
          ],
          if (mentor.disponibilidad != null && mentor.disponibilidad!.isNotEmpty) ...[
            const SizedBox(height: 10),
            MetaRow(icono: Icons.schedule_rounded, texto: mentor.disponibilidad!),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: solicitado
                ? OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.check_rounded, size: 17),
                    label: const Text('Solicitud enviada'),
                  )
                : ElevatedButton(
                    onPressed: solicitando ? null : onSolicitar,
                    child: solicitando
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                          )
                        : const Text('Pedir mentoría'),
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mis mentorías
// ---------------------------------------------------------------------------

class _MisMentoriasTab extends StatefulWidget {
  const _MisMentoriasTab();

  @override
  State<_MisMentoriasTab> createState() => _MisMentoriasTabState();
}

class _MisMentoriasTabState extends State<_MisMentoriasTab> {
  late Future<List<Mentoria>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Mentoria>> _load() => context.read<AuthController>().api.misMentorias();

  void _reload() => setState(() {
        _future = _load();
      });

  @override
  Widget build(BuildContext context) {
    return RumboRefresh(
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
                : 'No pudimos cargar tus mentorías';
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
                icono: Icons.handshake_outlined,
                titulo: 'Todavía no pediste mentoría',
                detalle: 'Buscá un mentor en la otra pestaña y mandale una solicitud.',
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            itemCount: mentorias.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final m = mentorias[i];
              final aceptada = m.estado == 'aceptada';
              return FadeSlideIn(
                key: ValueKey(m.id),
                index: i,
                child: RumboCard(
                  padding: const EdgeInsets.all(15),
                  onTap: aceptada
                      ? () => Navigator.of(context).push(
                            RumboPageRoute(builder: (_) => MentoriaChatScreen(mentoria: m)),
                          )
                      : null,
                  child: Row(
                    children: [
                      EstadoMentoriaIcono(estado: m.estado),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.mentorNombre, style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 3),
                            Text(
                              etiquetaEstadoMentoria(m.estado),
                              style: const TextStyle(color: RumboColors.textLow, fontSize: 12.8),
                            ),
                            const SizedBox(height: 5),
                            MetaRow(
                              icono: Icons.send_outlined,
                              texto: 'Enviada ${haceCuantoIso(m.fechaSolicitud)}',
                            ),
                          ],
                        ),
                      ),
                      if (aceptada)
                        const Icon(Icons.chat_bubble_outline_rounded, size: 19, color: RumboColors.success),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Estado de una mentoría (compartido con la pantalla del mentor)
// ---------------------------------------------------------------------------

String etiquetaEstadoMentoria(String estado) {
  switch (estado) {
    case 'aceptada':
      return 'Aceptada — tocá para chatear';
    case 'rechazada':
      return 'Rechazada';
    default:
      return 'Pendiente de respuesta';
  }
}

class EstadoMentoriaIcono extends StatelessWidget {
  final String estado;

  const EstadoMentoriaIcono({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final IconData icono;
    switch (estado) {
      case 'aceptada':
        color = RumboColors.success;
        icono = Icons.check_rounded;
      case 'rechazada':
        color = RumboColors.danger;
        icono = Icons.close_rounded;
      default:
        color = RumboColors.warning;
        icono = Icons.hourglass_empty_rounded;
    }
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Icon(icono, color: color, size: 19),
    );
  }
}
