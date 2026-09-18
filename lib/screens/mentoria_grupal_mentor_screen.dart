import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/mentoria_grupal.dart';
import '../services/api_client.dart';
import '../services/auth_controller.dart';
import '../theme.dart';
import '../utils/formato.dart';
import '../widgets/ui_kit.dart';
import 'mentoria_grupal_form_screen.dart';
import 'mentoria_grupal_screen.dart' show abrirLinkMeet;

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
      RumboPageRoute(builder: (_) => const MentoriaGrupalFormScreen()),
    );
    if (creada == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis sesiones grupales')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nuevaMentoria,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva'),
      ),
      body: SafeArea(
        top: false,
        child: RumboRefresh(
          onRefresh: () async {
            _reload();
            await _future.catchError((_) => <MentoriaGrupal>[]);
          },
          child: FutureBuilder<List<MentoriaGrupal>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SkeletonList(cantidad: 3);
              }
              if (snapshot.hasError) {
                final msg = snapshot.error is ApiException
                    ? (snapshot.error as ApiException).message
                    : 'No pudimos cargar tus sesiones';
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
              final grupales = snapshot.data ?? [];
              if (grupales.isEmpty) {
                return const ScrollableStatusView(
                  view: StatusView(
                    icono: Icons.campaign_outlined,
                    titulo: 'Todavía no publicaste ninguna',
                    detalle: 'Tocá "Nueva" para abrir tu primera sesión grupal.',
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                itemCount: grupales.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) => FadeSlideIn(
                  key: ValueKey(grupales[i].id),
                  index: i,
                  child: _SesionCard(grupal: grupales[i]),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SesionCard extends StatelessWidget {
  final MentoriaGrupal grupal;

  const _SesionCard({required this.grupal});

  @override
  Widget build(BuildContext context) {
    final g = grupal;
    final fraccion = g.cupoMaximo == 0 ? 0.0 : (g.inscritos / g.cupoMaximo).clamp(0.0, 1.0);
    final colorCupo = g.lleno ? RumboColors.warning : RumboColors.success;

    return RumboCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(g.titulo, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              MetaRow(
                icono: Icons.event_rounded,
                texto: fechaHora(g.fechaHora),
                color: RumboColors.navyBright,
              ),
              MetaRow(
                icono: Icons.people_outline_rounded,
                texto: '${g.inscritos}/${g.cupoMaximo} inscritos',
                color: colorCupo,
              ),
            ],
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: fraccion),
            duration: RumboMotion.slow,
            curve: RumboMotion.decelerate,
            builder: (context, v, _) => ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: v,
                minHeight: 5,
                backgroundColor: RumboColors.surfaceHigh,
                valueColor: AlwaysStoppedAnimation(colorCupo),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    RumboPageRoute(builder: (_) => InscritosGrupalScreen(grupal: g)),
                  ),
                  icon: const Icon(Icons.people_outline_rounded, size: 17),
                  label: const Text('Ver inscritos'),
                ),
              ),
              const SizedBox(width: 10),
              PressableScale(
                onTap: () => abrirLinkMeet(context, g.meetLink),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: RumboColors.navyRaised,
                    borderRadius: RumboRadii.field,
                    border: Border.all(color: RumboColors.outline),
                  ),
                  child: const Icon(Icons.videocam_outlined, color: RumboColors.navyBright, size: 20),
                ),
              ),
            ],
          ),
        ],
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
    _future = _load();
  }

  Future<List<InscritoGrupal>> _load() =>
      context.read<AuthController>().api.inscritosMentoriaGrupal(widget.grupal.id);

  void _reload() => setState(() {
        _future = _load();
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.grupal.titulo)),
      body: SafeArea(
        top: false,
        child: FutureBuilder<List<InscritoGrupal>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SkeletonList(cantidad: 4);
            }
            if (snapshot.hasError) {
              final msg = snapshot.error is ApiException
                  ? (snapshot.error as ApiException).message
                  : 'No pudimos cargar los inscritos';
              return StatusView(
                icono: Icons.cloud_off_rounded,
                titulo: 'No se pudo conectar',
                detalle: msg,
                textoAccion: 'Reintentar',
                onAccion: _reload,
                esError: true,
              );
            }
            final inscritos = snapshot.data ?? [];
            if (inscritos.isEmpty) {
              return const StatusView(
                icono: Icons.person_add_alt_outlined,
                titulo: 'Todavía no se unió nadie',
                detalle: 'Cuando alguien se inscriba, lo vas a ver acá con su contacto.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              itemCount: inscritos.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      inscritos.length == 1
                          ? '1 persona inscrita'
                          : '${inscritos.length} personas inscritas',
                      style: const TextStyle(color: RumboColors.textLow, fontSize: 12.5),
                    ),
                  );
                }
                final p = inscritos[i - 1];
                return FadeSlideIn(
                  index: i - 1,
                  child: RumboCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            gradient: RumboColors.navyGradient,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            p.nombre.isNotEmpty ? p.nombre.substring(0, 1).toUpperCase() : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.nombre, style: Theme.of(context).textTheme.titleSmall),
                              const SizedBox(height: 2),
                              Text(
                                p.email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: RumboColors.textLow, fontSize: 12.5),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          haceCuanto(p.fechaInscripcion),
                          style: const TextStyle(color: RumboColors.textLow, fontSize: 11),
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
