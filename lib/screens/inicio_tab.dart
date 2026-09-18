import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/checkin.dart';
import '../models/dashboard.dart';
import '../services/api_client.dart';
import '../services/auth_controller.dart';
import '../theme.dart';
import '../utils/formato.dart';
import '../widgets/ui_kit.dart';

class InicioTab extends StatefulWidget {
  const InicioTab({super.key});

  @override
  State<InicioTab> createState() => _InicioTabState();
}

class _InicioTabState extends State<InicioTab> {
  late Future<DashboardData> _future;
  int? _nivelSeleccionado;
  bool _enviandoCheckin = false;
  CheckinResult? _ultimoResultado;
  List<RecursoApoyo>? _recursosApoyo;
  String? _checkinError;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<DashboardData> _load() => context.read<AuthController>().api.dashboard();

  void _reload() => setState(() {
        _future = _load();
      });

  Future<void> _enviarCheckin(int nivel) async {
    HapticFeedback.mediumImpact();
    setState(() {
      _nivelSeleccionado = nivel;
      _enviandoCheckin = true;
      _checkinError = null;
      _ultimoResultado = null;
      _recursosApoyo = null;
    });
    try {
      final api = context.read<AuthController>().api;
      final resultado = await api.crearCheckin(nivel);
      if (!mounted) return;
      setState(() => _ultimoResultado = resultado);
      if (resultado.mostrarDerivacionApoyo) {
        final recursos = await api.recursosApoyo();
        if (mounted) setState(() => _recursosApoyo = recursos);
      }
      _reload();
    } on ApiException catch (e) {
      if (mounted) setState(() => _checkinError = e.message);
    } catch (_) {
      if (mounted) setState(() => _checkinError = 'No se pudo registrar tu check-in');
    } finally {
      if (mounted) setState(() => _enviandoCheckin = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    final nombre = user?.nombre.split(' ').first ?? '';

    return Scaffold(
      body: RumboRefresh(
        onRefresh: () async {
          _reload();
          await _future.catchError((_) => DashboardData(
                totalCheckins: 0,
                promedioEmocional: null,
                totalCvReviews: 0,
                totalInterviewSessions: 0,
                badges: const [],
                ultimosCheckins: const [],
              ));
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
          children: [
            SafeArea(bottom: false, child: FadeSlideIn(index: 0, child: _Saludo(nombre: nombre))),
            const SizedBox(height: 20),
            FadeSlideIn(
              index: 1,
              child: _CheckinCard(
                seleccionado: _nivelSeleccionado,
                enviando: _enviandoCheckin,
                resultado: _ultimoResultado,
                error: _checkinError,
                onSeleccionar: _enviarCheckin,
              ),
            ),
            if (_recursosApoyo != null) ...[
              const SizedBox(height: 14),
              _RecursosApoyoCard(recursos: _recursosApoyo!),
            ],
            const SizedBox(height: 26),
            FutureBuilder<DashboardData>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _ResumenSkeleton();
                }
                if (snapshot.hasError) {
                  final msg = snapshot.error is ApiException
                      ? (snapshot.error as ApiException).message
                      : 'No pudimos cargar tu resumen';
                  return StatusView(
                    icono: Icons.cloud_off_rounded,
                    titulo: 'Sin conexión con el servidor',
                    detalle: msg,
                    textoAccion: 'Reintentar',
                    onAccion: _reload,
                    esError: true,
                  );
                }
                return _Resumen(data: snapshot.data!);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Saludo extends StatelessWidget {
  final String nombre;

  const _Saludo({required this.nombre});

  String get _momento {
    final h = DateTime.now().hour;
    if (h < 6) return 'Buenas noches';
    if (h < 13) return 'Buenos días';
    if (h < 20) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    return BrandHeader(
      icono: Icons.explore_outlined,
      titulo: nombre.isEmpty ? _momento : '$_momento, $nombre',
      subtitulo: 'Un paso por día te acerca a tu primera oportunidad.',
    );
  }
}

// ---------------------------------------------------------------------------
// Check-in de bienestar
// ---------------------------------------------------------------------------

const List<String> _emojis = ['😞', '🙁', '😐', '🙂', '😄'];
const List<String> _etiquetasNivel = ['Muy mal', 'Bajón', 'Neutral', 'Bien', 'Genial'];

class _CheckinCard extends StatelessWidget {
  final int? seleccionado;
  final bool enviando;
  final CheckinResult? resultado;
  final String? error;
  final ValueChanged<int> onSeleccionar;

  const _CheckinCard({
    required this.seleccionado,
    required this.enviando,
    required this.resultado,
    required this.error,
    required this.onSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    return RumboCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite_outline, size: 18, color: RumboColors.crimsonBright),
              const SizedBox(width: 8),
              Text('¿Cómo te sentís hoy?', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Tu check-in diario ajusta cuánto te proponemos avanzar.',
            style: TextStyle(color: RumboColors.textLow, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (i) {
              final nivel = i + 1;
              return _EmojiBoton(
                emoji: _emojis[i],
                etiqueta: _etiquetasNivel[i],
                seleccionado: seleccionado == nivel,
                habilitado: !enviando,
                onTap: () => onSeleccionar(nivel),
              );
            }),
          ),
          if (enviando) ...[
            const SizedBox(height: 18),
            const Center(
              child: SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.4)),
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 18),
            InfoBanner(mensaje: error!),
          ],
          if (!enviando && resultado != null) ...[
            const SizedBox(height: 18),
            InfoBanner(mensaje: resultado!.mensaje, tono: BannerTono.exito),
            if (resultado!.cargaRecomendada.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.tune_rounded, size: 14, color: RumboColors.textLow),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Carga sugerida para hoy: ${resultado!.cargaRecomendada}',
                      style: const TextStyle(color: RumboColors.textLow, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Emoji que crece y se enciende al elegirlo. El tamaño del área tocable se
/// mantiene fijo para que la fila no se mueva al cambiar de selección.
class _EmojiBoton extends StatelessWidget {
  final String emoji;
  final String etiqueta;
  final bool seleccionado;
  final bool habilitado;
  final VoidCallback onTap;

  const _EmojiBoton({
    required this.emoji,
    required this.etiqueta,
    required this.seleccionado,
    required this.habilitado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: habilitado ? onTap : null,
      child: SizedBox(
        width: 58,
        child: Column(
          children: [
            AnimatedContainer(
              duration: RumboMotion.medium,
              curve: RumboMotion.spring,
              width: seleccionado ? 50 : 44,
              height: seleccionado ? 50 : 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: seleccionado ? RumboColors.crimson.withValues(alpha: 0.18) : RumboColors.surfaceRaised,
                border: Border.all(
                  color: seleccionado ? RumboColors.crimsonBright : RumboColors.outline,
                  width: seleccionado ? 1.8 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: AnimatedScale(
                duration: RumboMotion.medium,
                curve: RumboMotion.spring,
                scale: seleccionado ? 1.14 : 1,
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(height: 7),
            AnimatedDefaultTextStyle(
              duration: RumboMotion.fast,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: seleccionado ? FontWeight.w700 : FontWeight.w500,
                color: seleccionado ? RumboColors.crimsonBright : RumboColors.textLow,
              ),
              child: Text(etiqueta, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecursosApoyoCard extends StatelessWidget {
  final List<RecursoApoyo> recursos;

  const _RecursosApoyoCard({required this.recursos});

  @override
  Widget build(BuildContext context) {
    return RumboCard(
      color: RumboColors.warningSoft,
      borderColor: RumboColors.warning.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.support_agent_rounded, color: RumboColors.warning, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Notamos que venís sintiéndote mal',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: RumboColors.warning),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Estos recursos pueden ayudarte. Pedir ayuda también es avanzar.',
            style: TextStyle(color: RumboColors.textMid, fontSize: 13, height: 1.45),
          ),
          const SizedBox(height: 16),
          for (final r in recursos) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: RumboColors.ink.withValues(alpha: 0.35),
                borderRadius: RumboRadii.field,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.nombre,
                    style: const TextStyle(color: RumboColors.textHigh, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    r.descripcion,
                    style: const TextStyle(color: RumboColors.textMid, fontSize: 12.5, height: 1.4),
                  ),
                  const SizedBox(height: 7),
                  MetaRow(icono: Icons.phone_outlined, texto: r.contacto, color: RumboColors.warning),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Resumen de progreso
// ---------------------------------------------------------------------------

class _Resumen extends StatelessWidget {
  final DashboardData data;

  const _Resumen({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FadeSlideIn(index: 2, child: SectionTitle('Tu progreso')),
        const SizedBox(height: 14),
        FadeSlideIn(
          index: 3,
          child: Row(
            children: [
              Expanded(
                child: StatCard(
                  icono: Icons.favorite_rounded,
                  etiqueta: 'Check-ins',
                  valor: data.totalCheckins,
                  acento: RumboColors.crimsonBright,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icono: Icons.description_outlined,
                  etiqueta: 'CVs revisados',
                  valor: data.totalCvReviews,
                  acento: RumboColors.navyBright,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FadeSlideIn(
          index: 4,
          child: Row(
            children: [
              Expanded(
                child: StatCard(
                  icono: Icons.forum_outlined,
                  etiqueta: 'Entrevistas',
                  valor: data.totalInterviewSessions,
                  acento: RumboColors.navyBright,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icono: Icons.emoji_events_outlined,
                  etiqueta: 'Insignias',
                  valor: data.badges.length,
                  acento: RumboColors.warning,
                ),
              ),
            ],
          ),
        ),
        if (data.promedioEmocional != null) ...[
          const SizedBox(height: 20),
          FadeSlideIn(index: 5, child: _AnimoPromedio(promedio: data.promedioEmocional!)),
        ],
        if (data.ultimosCheckins.isNotEmpty) ...[
          const SizedBox(height: 28),
          const FadeSlideIn(index: 6, child: SectionTitle('Últimos check-ins')),
          const SizedBox(height: 12),
          FadeSlideIn(
            index: 7,
            child: RumboCard(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Column(
                children: [
                  for (var i = 0; i < data.ultimosCheckins.length; i++) ...[
                    if (i > 0) const Divider(indent: 56, endIndent: 12),
                    _FilaCheckin(checkin: data.ultimosCheckins[i]),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Barra que ubica el promedio emocional dentro de la escala 1..5.
class _AnimoPromedio extends StatelessWidget {
  final double promedio;

  const _AnimoPromedio({required this.promedio});

  @override
  Widget build(BuildContext context) {
    final fraccion = ((promedio - 1) / 4).clamp(0.0, 1.0);
    return RumboCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, size: 17, color: RumboColors.navyBright),
              const SizedBox(width: 8),
              Text('Tu ánimo promedio', style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              Text(
                promedio.toStringAsFixed(1),
                style: const TextStyle(
                  color: RumboColors.textHigh,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(' / 5', style: TextStyle(color: RumboColors.textLow, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 14),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: fraccion),
            duration: RumboMotion.slow,
            curve: RumboMotion.decelerate,
            builder: (context, v, _) => ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Stack(
                children: [
                  Container(height: 8, color: RumboColors.surfaceHigh),
                  FractionallySizedBox(
                    widthFactor: v,
                    child: Container(
                      height: 8,
                      decoration: const BoxDecoration(gradient: RumboColors.brandGradient),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaCheckin extends StatelessWidget {
  final CheckinResult checkin;

  const _FilaCheckin({required this.checkin});

  @override
  Widget build(BuildContext context) {
    final indice = (checkin.nivelEmocional - 1).clamp(0, 4);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: RumboColors.surfaceRaised, shape: BoxShape.circle),
        child: Text(_emojis[indice], style: const TextStyle(fontSize: 19)),
      ),
      title: Text(_etiquetasNivel[indice], style: Theme.of(context).textTheme.titleSmall),
      subtitle: Text(fechaCortaIso(checkin.fecha)),
      trailing: Text(
        haceCuantoIso(checkin.fecha),
        style: const TextStyle(color: RumboColors.textLow, fontSize: 11.5),
      ),
    );
  }
}

class _ResumenSkeleton extends StatelessWidget {
  const _ResumenSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Skeleton(width: 130, height: 17),
        const SizedBox(height: 16),
        Row(
          children: [
            for (var i = 0; i < 2; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              const Expanded(child: SkeletonCard(lineas: 1)),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var i = 0; i < 2; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              const Expanded(child: SkeletonCard(lineas: 1)),
            ],
          ],
        ),
      ],
    );
  }
}
