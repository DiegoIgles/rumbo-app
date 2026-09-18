import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/badge.dart';
import '../services/api_client.dart';
import '../services/auth_controller.dart';
import '../theme.dart';
import '../utils/formato.dart';
import '../widgets/ui_kit.dart';

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
    _future = _load();
  }

  Future<List<AppBadge>> _load() => context.read<AuthController>().api.badges();

  void _reload() => setState(() {
        _future = _load();
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Insignias')),
      body: SafeArea(
        top: false,
        child: FutureBuilder<List<AppBadge>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SkeletonList(cantidad: 3);
            }
            if (snapshot.hasError) {
              final msg = snapshot.error is ApiException
                  ? (snapshot.error as ApiException).message
                  : 'No pudimos cargar tus insignias';
              return StatusView(
                icono: Icons.cloud_off_rounded,
                titulo: 'No se pudo conectar',
                detalle: msg,
                textoAccion: 'Reintentar',
                onAccion: _reload,
                esError: true,
              );
            }

            final obtenidas = snapshot.data ?? [];
            final porTipo = {for (final b in obtenidas) b.tipo: b};
            // Se listan TODAS las del catálogo, no solo las obtenidas: ver las
            // que faltan (y cómo se consiguen) es lo que las vuelve una meta.
            final tipos = badgeCatalogo.keys.toList();
            for (final b in obtenidas) {
              if (!tipos.contains(b.tipo)) tipos.add(b.tipo);
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                FadeSlideIn(index: 0, child: _Progreso(obtenidas: obtenidas.length, total: tipos.length)),
                const SizedBox(height: 24),
                for (var i = 0; i < tipos.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  FadeSlideIn(
                    index: i + 1,
                    child: _TarjetaInsignia(tipo: tipos[i], badge: porTipo[tipos[i]]),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Progreso extends StatelessWidget {
  final int obtenidas;
  final int total;

  const _Progreso({required this.obtenidas, required this.total});

  @override
  Widget build(BuildContext context) {
    final fraccion = total == 0 ? 0.0 : obtenidas / total;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: RumboColors.navyGradient,
        borderRadius: BorderRadius.circular(RumboRadii.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: RumboColors.warning, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  obtenidas == 0
                      ? 'Todavía no desbloqueaste ninguna'
                      : '$obtenidas de $total desbloqueadas',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: fraccion),
            duration: RumboMotion.slow,
            curve: RumboMotion.decelerate,
            builder: (context, v, _) => ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: v,
                minHeight: 7,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation(RumboColors.warning),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            obtenidas == 0
                ? 'Hacé un check-in, revisá tu CV o practicá una entrevista para ganar la primera.'
                : 'Seguí usando Rumbo para completarlas todas.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12.8, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _TarjetaInsignia extends StatelessWidget {
  final String tipo;
  final AppBadge? badge;

  const _TarjetaInsignia({required this.tipo, required this.badge});

  @override
  Widget build(BuildContext context) {
    final info = infoBadge(tipo);
    final desbloqueada = badge != null;
    final color = desbloqueada ? RumboColors.warning : RumboColors.textLow;

    return RumboCard(
      padding: const EdgeInsets.all(16),
      borderColor: desbloqueada ? RumboColors.warning.withValues(alpha: 0.32) : null,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: desbloqueada ? 0.15 : 0.07),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: desbloqueada ? 0.5 : 0.2)),
            ),
            child: Icon(
              desbloqueada ? Icons.emoji_events_rounded : Icons.lock_outline_rounded,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.titulo,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: desbloqueada ? RumboColors.textHigh : RumboColors.textMid,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  info.descripcion,
                  style: const TextStyle(color: RumboColors.textLow, fontSize: 12.8, height: 1.4),
                ),
                if (desbloqueada) ...[
                  const SizedBox(height: 8),
                  RumboTag(
                    texto: 'Obtenida el ${fechaCortaIso(badge!.fechaObtenida)}',
                    color: RumboColors.warning,
                    icono: Icons.check_rounded,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
