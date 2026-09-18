import 'package:flutter/material.dart';

import '../theme.dart';

/// Avatar circular que "habla" (pulsa y emite anillos) mientras la IA está
/// reproduciendo audio por texto-a-voz. Simula una llamada con la IA.
class AiAvatar extends StatefulWidget {
  final bool speaking;
  final double size;

  const AiAvatar({super.key, required this.speaking, this.size = 96});

  @override
  State<AiAvatar> createState() => _AiAvatarState();
}

class _AiAvatarState extends State<AiAvatar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final hablando = widget.speaking;
        final pulso = hablando ? (0.5 + 0.5 * (1 - (2 * _controller.value - 1).abs())) : 0.0;
        final escala = 1 + pulso * 0.14;
        return SizedBox(
          width: widget.size * 1.8,
          height: widget.size * 1.8,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (hablando)
                for (final fase in [0.0, 0.5])
                  Builder(
                    builder: (context) {
                      final t = (_controller.value + fase) % 1.0;
                      return Opacity(
                        opacity: (1 - t) * 0.45,
                        child: Container(
                          width: widget.size * (1 + t * 0.9),
                          height: widget.size * (1 + t * 0.9),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: rumboPrimary, width: 2),
                          ),
                        ),
                      );
                    },
                  ),
              Transform.scale(
                scale: escala,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [rumboPrimary, Color(0xFF22D3EE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(color: rumboPrimary.withValues(alpha: hablando ? 0.55 : 0.25), blurRadius: 18, spreadRadius: 2),
                    ],
                  ),
                  child: Icon(Icons.auto_awesome, color: Colors.white, size: widget.size * 0.4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
