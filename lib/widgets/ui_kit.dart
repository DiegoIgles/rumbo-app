import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// Piezas compartidas por todas las pantallas. Están acá y no repetidas en cada
/// screen para que un cambio de estilo se haga en un solo lugar.

// ---------------------------------------------------------------------------
// Entrada escalonada
// ---------------------------------------------------------------------------

/// Hace aparecer a su hijo con un fundido + un desplazamiento corto hacia
/// arriba. Con [index] se escalona una lista: cada elemento arranca un poco
/// después que el anterior, que es lo que da la sensación de "cascada".
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delayStep;
  final double offset;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.delayStep = const Duration(milliseconds: 55),
    this.offset = 18,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: RumboMotion.medium,
  );

  @override
  void initState() {
    super.initState();
    // El escalonado se corta a los 8 elementos: más allá, el último tardaría
    // tanto en aparecer que se leería como un bug y no como una animación.
    final pasos = math.min(widget.index, 8);
    Future<void>.delayed(widget.delayStep * pasos, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _controller, curve: RumboMotion.decelerate);
    return FadeTransition(
      opacity: curved,
      child: AnimatedBuilder(
        animation: curved,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, widget.offset * (1 - curved.value)),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Micro-interacción de pulsado
// ---------------------------------------------------------------------------

/// Envuelve cualquier cosa tocable y la encoge levemente mientras el dedo está
/// apoyado. Es el detalle que más cambia la percepción de "responde rápido".
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool haptics;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
    this.haptics = true,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final habilitado = widget.onTap != null;
    return GestureDetector(
      onTapDown: habilitado ? (_) => _set(true) : null,
      onTapUp: habilitado ? (_) => _set(false) : null,
      onTapCancel: habilitado ? () => _set(false) : null,
      onTap: habilitado
          ? () {
              if (widget.haptics) HapticFeedback.selectionClick();
              widget.onTap!();
            }
          : null,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: RumboMotion.fast,
        curve: RumboMotion.emphasized,
        child: widget.child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Contenedores
// ---------------------------------------------------------------------------

/// Tarjeta base. Si recibe [onTap] se vuelve pulsable con la micro-interacción.
class RumboCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;

  const RumboCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(18),
    this.color,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final contenido = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? RumboColors.surface,
        borderRadius: RumboRadii.card,
        border: Border.all(color: borderColor ?? RumboColors.outlineSoft),
      ),
      child: child,
    );
    if (onTap == null) return contenido;
    return PressableScale(onTap: onTap, child: contenido);
  }
}

/// Cabecera con el degradado de marca. Se usa arriba de las pantallas
/// principales para anclar la identidad visual.
class BrandHeader extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final Widget? trailing;
  final IconData? icono;

  const BrandHeader({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.trailing,
    this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
      decoration: BoxDecoration(
        gradient: RumboColors.brandGradient,
        borderRadius: BorderRadius.circular(RumboRadii.xl),
      ),
      child: Row(
        children: [
          if (icono != null) ...[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(RumboRadii.md),
              ),
              child: Icon(icono, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                if (subtitulo != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitulo!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Título de sección con una barra de acento a la izquierda.
class SectionTitle extends StatelessWidget {
  final String texto;
  final Widget? accion;

  const SectionTitle(this.texto, {super.key, this.accion});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 17,
          decoration: BoxDecoration(
            color: RumboColors.crimson,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(texto, style: Theme.of(context).textTheme.titleMedium),
        ),
        ?accion,
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Métricas
// ---------------------------------------------------------------------------

/// Número que cuenta desde 0 hasta [valor] al aparecer.
class AnimatedCounter extends StatelessWidget {
  final int valor;
  final TextStyle? style;

  const AnimatedCounter({super.key, required this.valor, this.style});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: valor.toDouble()),
      duration: RumboMotion.slow,
      curve: RumboMotion.decelerate,
      builder: (context, v, _) => Text(v.round().toString(), style: style),
    );
  }
}

class StatCard extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final int valor;
  final Color? acento;

  const StatCard({
    super.key,
    required this.icono,
    required this.etiqueta,
    required this.valor,
    this.acento,
  });

  @override
  Widget build(BuildContext context) {
    final color = acento ?? RumboColors.crimsonBright;
    return RumboCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(RumboRadii.sm),
            ),
            child: Icon(icono, color: color, size: 19),
          ),
          const SizedBox(height: 14),
          AnimatedCounter(
            valor: valor,
            style: const TextStyle(
              color: RumboColors.textHigh,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 2),
          Text(etiqueta, style: const TextStyle(color: RumboColors.textLow, fontSize: 12.5)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Estados: carga, vacío, error
// ---------------------------------------------------------------------------

/// Bloque gris que late. Se usa para armar esqueletos con la forma del
/// contenido real, en vez de un spinner centrado que no dice nada.
class Skeleton extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;

  const Skeleton({super.key, this.width, this.height = 14, this.radius = 8});

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1250),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Color.lerp(RumboColors.surface, RumboColors.surfaceHigh, _controller.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// Esqueleto con forma de tarjeta de lista.
class SkeletonCard extends StatelessWidget {
  final int lineas;

  const SkeletonCard({super.key, this.lineas = 2});

  @override
  Widget build(BuildContext context) {
    return RumboCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Skeleton(width: 170, height: 16),
          const SizedBox(height: 14),
          for (var i = 0; i < lineas; i++) ...[
            Skeleton(width: i.isEven ? double.infinity : 210, height: 11),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  final int cantidad;
  final EdgeInsetsGeometry padding;

  const SkeletonList({super.key, this.cantidad = 4, this.padding = const EdgeInsets.all(20)});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      itemCount: cantidad,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => FadeSlideIn(index: i, child: const SkeletonCard()),
    );
  }
}

/// Estado vacío o de error. [esError] solo cambia el color del icono; el resto
/// del layout es igual para que la app no "salte" entre uno y otro.
class StatusView extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String? detalle;
  final String? textoAccion;
  final VoidCallback? onAccion;
  final bool esError;

  const StatusView({
    super.key,
    required this.icono,
    required this.titulo,
    this.detalle,
    this.textoAccion,
    this.onAccion,
    this.esError = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = esError ? RumboColors.danger : RumboColors.navyBright;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icono, color: color, size: 32),
            ),
            const SizedBox(height: 20),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (detalle != null) ...[
              const SizedBox(height: 8),
              Text(
                detalle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (textoAccion != null && onAccion != null) ...[
              const SizedBox(height: 22),
              OutlinedButton(onPressed: onAccion, child: Text(textoAccion!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Igual que [StatusView] pero scrolleable, para poder usarlo dentro de un
/// RefreshIndicator (que necesita un hijo que scrollee para poder tirar).
class ScrollableStatusView extends StatelessWidget {
  final StatusView view;

  const ScrollableStatusView({super.key, required this.view});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: view,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Avisos y botones
// ---------------------------------------------------------------------------

enum BannerTono { error, exito, aviso, info }

class InfoBanner extends StatelessWidget {
  final String mensaje;
  final BannerTono tono;
  final IconData? icono;

  const InfoBanner({super.key, required this.mensaje, this.tono = BannerTono.error, this.icono});

  @override
  Widget build(BuildContext context) {
    late final Color fondo;
    late final Color acento;
    late final IconData iconoPorDefecto;
    switch (tono) {
      case BannerTono.exito:
        fondo = RumboColors.successSoft;
        acento = RumboColors.success;
        iconoPorDefecto = Icons.check_circle_outline;
      case BannerTono.aviso:
        fondo = RumboColors.warningSoft;
        acento = RumboColors.warning;
        iconoPorDefecto = Icons.info_outline;
      case BannerTono.info:
        fondo = RumboColors.navyRaised;
        acento = RumboColors.navyBright;
        iconoPorDefecto = Icons.lightbulb_outline;
      case BannerTono.error:
        fondo = RumboColors.dangerSoft;
        acento = RumboColors.danger;
        iconoPorDefecto = Icons.error_outline;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: RumboMotion.medium,
      curve: RumboMotion.decelerate,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 8 * (1 - v)), child: child),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: RumboRadii.field,
          border: Border.all(color: acento.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono ?? iconoPorDefecto, color: acento, size: 19),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                mensaje,
                style: TextStyle(color: acento, fontSize: 13.5, height: 1.4, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón principal a ancho completo que muestra su propio spinner.
class LoadingButton extends StatelessWidget {
  final String texto;
  final String? textoCargando;
  final bool cargando;
  final VoidCallback? onPressed;
  final IconData? icono;

  const LoadingButton({
    super.key,
    required this.texto,
    required this.cargando,
    required this.onPressed,
    this.textoCargando,
    this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: cargando ? null : onPressed,
        child: AnimatedSwitcher(
          duration: RumboMotion.fast,
          child: cargando
              ? Row(
                  key: const ValueKey('cargando'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 17,
                      width: 17,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white70),
                    ),
                    if (textoCargando != null) ...[
                      const SizedBox(width: 12),
                      Text(textoCargando!),
                    ],
                  ],
                )
              : Row(
                  key: const ValueKey('normal'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icono != null) ...[
                      Icon(icono, size: 18),
                      const SizedBox(width: 9),
                    ],
                    Text(texto),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Etiqueta corta con color propio (área, modalidad, estado...).
class RumboTag extends StatelessWidget {
  final String texto;
  final Color color;
  final IconData? icono;

  const RumboTag({super.key, required this.texto, required this.color, this.icono});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: RumboRadii.pill,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, size: 12, color: color),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila de icono + texto para metadatos (ciudad, modalidad, fecha...).
class MetaRow extends StatelessWidget {
  final IconData icono;
  final String texto;
  final Color? color;

  const MetaRow({super.key, required this.icono, required this.texto, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? RumboColors.textLow;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 13.5, color: c),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            texto,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: c, fontSize: 12.5),
          ),
        ),
      ],
    );
  }
}

/// RefreshIndicator con los colores de la marca, para no repetirlos.
class RumboRefresh extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const RumboRefresh({super.key, required this.onRefresh, required this.child});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: RumboColors.crimsonBright,
      backgroundColor: RumboColors.surfaceRaised,
      child: child,
    );
  }
}
