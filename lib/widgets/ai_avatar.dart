import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Avatar de la IA durante la práctica de entrevista.
///
/// Tiene tres estados visuales distintos, porque en una videollamada lo único
/// que orienta al usuario es saber de quién es el turno:
///  - hablando:  emite anillos hacia afuera y late.
///  - escuchando: un anillo respira suave alrededor (la IA "espera").
///  - pensando:  tres puntos girando.
class AiAvatar extends StatefulWidget {
  final bool speaking;
  final bool listening;
  final bool thinking;
  final double size;

  const AiAvatar({
    super.key,
    required this.speaking,
    this.listening = false,
    this.thinking = false,
    this.size = 96,
  });

  @override
  State<AiAvatar> createState() => _AiAvatarState();
}

class _AiAvatarState extends State<AiAvatar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 2,
      height: widget.size * 2,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          // Onda triangular 0→1→0: el latido sube y baja de forma pareja.
          final pulso = 1 - (2 * t - 1).abs();

          return Stack(
            alignment: Alignment.center,
            children: [
              // Anillos que se expanden y se desvanecen mientras habla.
              if (widget.speaking)
                for (final fase in [0.0, 0.33, 0.66])
                  _Anillo(
                    progreso: (t + fase) % 1.0,
                    base: widget.size,
                    color: RumboColors.crimsonBright,
                  ),
              // Un solo anillo que respira mientras escucha.
              if (widget.listening)
                Container(
                  width: widget.size * (1.25 + pulso * 0.12),
                  height: widget.size * (1.25 + pulso * 0.12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: RumboColors.success.withValues(alpha: 0.25 + pulso * 0.35),
                      width: 2,
                    ),
                  ),
                ),
              Transform.scale(
                scale: widget.speaking ? 1 + pulso * 0.09 : 1,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RumboColors.brandGradient,
                    boxShadow: [
                      BoxShadow(
                        color: RumboColors.crimson.withValues(
                          alpha: widget.speaking ? 0.35 + pulso * 0.3 : 0.22,
                        ),
                        blurRadius: 34,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: widget.thinking
                      ? _PuntosPensando(progreso: t, size: widget.size)
                      : Icon(
                          widget.listening ? Icons.hearing_rounded : Icons.auto_awesome,
                          color: Colors.white,
                          size: widget.size * 0.36,
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Anillo extends StatelessWidget {
  final double progreso;
  final double base;
  final Color color;

  const _Anillo({required this.progreso, required this.base, required this.color});

  @override
  Widget build(BuildContext context) {
    final escala = 1 + progreso * 0.85;
    return Opacity(
      opacity: (1 - progreso) * 0.5,
      child: Container(
        width: base * escala,
        height: base * escala,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
      ),
    );
  }
}

/// Tres puntos girando alrededor del centro mientras la IA arma la respuesta.
class _PuntosPensando extends StatelessWidget {
  final double progreso;
  final double size;

  const _PuntosPensando({required this.progreso, required this.size});

  @override
  Widget build(BuildContext context) {
    final radio = size * 0.17;
    return Stack(
      alignment: Alignment.center,
      children: [
        for (var i = 0; i < 3; i++)
          Transform.translate(
            offset: Offset(
              radio * math.cos(2 * math.pi * (progreso + i / 3)),
              radio * math.sin(2 * math.pi * (progreso + i / 3)),
            ),
            child: Container(
              width: size * 0.09,
              height: size * 0.09,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            ),
          ),
      ],
    );
  }
}
