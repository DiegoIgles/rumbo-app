import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/mentoria_grupal.dart';
import '../services/api_client.dart';
import '../services/auth_controller.dart';
import '../theme.dart';
import '../utils/formato.dart';
import '../widgets/ui_kit.dart';

class MentoriaGrupalScreen extends StatefulWidget {
  const MentoriaGrupalScreen({super.key});

  @override
  State<MentoriaGrupalScreen> createState() => _MentoriaGrupalScreenState();
}

class _MentoriaGrupalScreenState extends State<MentoriaGrupalScreen> {
  late Future<List<MentoriaGrupal>> _future;
  final Set<String> _uniendose = {};

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<MentoriaGrupal>> _load() => context.read<AuthController>().api.mentoriasGrupales();

  void _reload() => setState(() {
        _future = _load();
      });

  Future<void> _unirse(MentoriaGrupal g) async {
    setState(() => _uniendose.add(g.id));
    try {
      await context.read<AuthController>().api.unirseMentoriaGrupal(g.id);
      _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('¡Te uniste a "${g.titulo}"!')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo unir a la mentoría')),
        );
      }
    } finally {
      if (mounted) setState(() => _uniendose.remove(g.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mentoría grupal')),
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
                    : 'No pudimos cargar las sesiones';
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
                    icono: Icons.groups_outlined,
                    titulo: 'Sin sesiones programadas',
                    detalle: 'Todavía no hay mentorías grupales publicadas. Volvé a mirar pronto.',
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                itemCount: grupales.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) => FadeSlideIn(
                  key: ValueKey(grupales[i].id),
                  index: i,
                  child: _GrupalCard(
                    grupal: grupales[i],
                    uniendose: _uniendose.contains(grupales[i].id),
                    onUnirse: () => _unirse(grupales[i]),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GrupalCard extends StatelessWidget {
  final MentoriaGrupal grupal;
  final bool uniendose;
  final VoidCallback onUnirse;

  const _GrupalCard({required this.grupal, required this.uniendose, required this.onUnirse});

  @override
  Widget build(BuildContext context) {
    final g = grupal;
    final fraccion = g.cupoMaximo == 0 ? 0.0 : (g.inscritos / g.cupoMaximo).clamp(0.0, 1.0);
    final colorCupo = g.lleno ? RumboColors.danger : RumboColors.success;

    return RumboCard(
      borderColor: g.yaInscrito ? RumboColors.success.withValues(alpha: 0.35) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(g.titulo, style: Theme.of(context).textTheme.titleMedium),
              ),
              if (g.yaInscrito) ...[
                const SizedBox(width: 10),
                const RumboTag(texto: 'Anotado', color: RumboColors.success, icono: Icons.check_rounded),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Con ${g.mentorNombre}',
            style: const TextStyle(color: RumboColors.textLow, fontSize: 13),
          ),
          const SizedBox(height: 14),
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
                texto: g.lleno
                    ? 'Cupo lleno (${g.inscritos}/${g.cupoMaximo})'
                    : '${g.cuposDisponibles} de ${g.cupoMaximo} libres',
                color: colorCupo,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Barra de ocupación: comunica la urgencia mejor que el número solo.
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
          const SizedBox(height: 14),
          Text(
            g.descripcion,
            style: const TextStyle(color: RumboColors.textMid, fontSize: 13.5, height: 1.5),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: g.yaInscrito
                ? OutlinedButton.icon(
                    onPressed: () => _abrirMeet(context, g.meetLink),
                    icon: const Icon(Icons.videocam_outlined, size: 18),
                    label: const Text('Abrir Meet'),
                  )
                : ElevatedButton(
                    onPressed: (g.lleno || uniendose) ? null : onUnirse,
                    child: uniendose
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                          )
                        : Text(g.lleno ? 'Cupo lleno' : 'Unirme'),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Abre el link de Meet en el navegador/app externa y avisa si no se pudo.
Future<void> _abrirMeet(BuildContext context, String link) async {
  final uri = Uri.tryParse(link);
  if (uri == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El link de la sesión no es válido')),
      );
    }
    return;
  }
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudo abrir el link de la sesión')),
    );
  }
}

/// Reexportado para la pantalla del mentor, que abre el mismo tipo de link.
Future<void> abrirLinkMeet(BuildContext context, String link) => _abrirMeet(context, link);
