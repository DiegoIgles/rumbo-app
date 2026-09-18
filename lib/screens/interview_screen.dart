import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../services/api_client.dart';
import '../services/auth_controller.dart';
import '../theme.dart';
import '../widgets/ai_avatar.dart';
import '../widgets/ui_kit.dart';
import 'interview_feedback_screen.dart';

class InterviewScreen extends StatefulWidget {
  const InterviewScreen({super.key});

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  late final ApiClient _api = context.read<AuthController>().api;
  final _sectorCtrl = TextEditingController();
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _speech = SpeechToText();

  String _modo = 'tradicional';
  String? _sessionId;
  bool _llamadaActiva = false;
  bool _iniciando = false;
  bool _finalizando = false;
  String? _error;

  bool _hablando = false;
  bool _escuchando = false;
  bool _procesando = false;
  bool _speechDisponible = false;

  CameraController? _cameraController;
  Future<void>? _cameraInitFuture;
  String? _errorCamara;

  /// Espera esta cantidad de silencio confirmado (sin transcripción nueva)
  /// antes de dar por terminado el turno del usuario y responder. Evita
  /// cortar al usuario en una pausa breve mientras piensa.
  static const _esperaSilencio = Duration(seconds: 2);
  Timer? _silencioTimer;
  String _ultimoTranscript = '';

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('es-ES');
    _tts.setSpeechRate(0.48);
    _tts.setCompletionHandler(() {
      if (!mounted || !_llamadaActiva) return;
      setState(() => _hablando = false);
      _comenzarEscucha();
    });
  }

  @override
  void dispose() {
    _silencioTimer?.cancel();
    _sectorCtrl.dispose();
    _tts.stop();
    _speech.stop();
    _cameraController?.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Cámara, voz y turno de habla
  // -------------------------------------------------------------------------

  Future<void> _iniciarCamara() async {
    try {
      final camaras = await availableCameras();
      if (camaras.isEmpty) {
        if (mounted) {
          setState(() => _errorCamara = 'No se encontró ninguna cámara en este dispositivo.');
        }
        return;
      }
      final frontal = camaras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => camaras.first,
      );
      final controller = CameraController(frontal, ResolutionPreset.medium, enableAudio: false);
      _cameraController = controller;
      _cameraInitFuture = controller.initialize();
      await _cameraInitFuture;
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        setState(() => _errorCamara = 'No se pudo acceder a la cámara. Podés seguir la práctica sin video.');
      }
    }
  }

  Future<void> _inicializarSpeech() async {
    final disponible = await _speech.initialize(
      onError: (_) {
        if (mounted) setState(() => _escuchando = false);
      },
    );
    _speechDisponible = disponible;
    if (!disponible && mounted) {
      setState(() => _error = 'No se pudo activar el micrófono. Revisá los permisos de la app.');
    }
  }

  Future<void> _iniciar() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _iniciando = true;
      _error = null;
    });
    try {
      final sector = _sectorCtrl.text.trim();
      final r = await _api.interviewStart(modo: _modo, sector: sector.isEmpty ? null : sector);
      if (!mounted) return;
      setState(() {
        _sessionId = r.sessionId;
        _llamadaActiva = true;
      });
      unawaited(_iniciarCamara());
      await _inicializarSpeech();
      unawaited(_hablar(r.mensajeInicial));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo iniciar la práctica');
    } finally {
      if (mounted) setState(() => _iniciando = false);
    }
  }

  Future<void> _hablar(String texto) async {
    if (mounted) setState(() => _hablando = true);
    await _tts.speak(texto);
  }

  Future<void> _comenzarEscucha() async {
    if (!_llamadaActiva || _escuchando || _procesando || _hablando) return;
    if (!_speechDisponible) {
      setState(() => _error = 'No se pudo activar el micrófono. Revisá los permisos y volvé a intentar.');
      return;
    }
    _ultimoTranscript = '';
    setState(() {
      _error = null;
      _escuchando = true;
    });
    // Usamos partialResults + un temporizador propio (en vez del corte automático
    // del reconocedor) para no responder ante una pausa breve mientras la persona
    // piensa: solo se considera terminado el turno tras _esperaSilencio sin novedades.
    await _speech.listen(
      onResult: (result) {
        if (mounted) setState(() => _ultimoTranscript = result.recognizedWords);
        _reiniciarTemporizadorSilencio();
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        pauseFor: const Duration(seconds: 8),
        listenFor: const Duration(seconds: 90),
      ),
    );
  }

  void _reiniciarTemporizadorSilencio() {
    _silencioTimer?.cancel();
    _silencioTimer = Timer(_esperaSilencio, _confirmarFinDeTurno);
  }

  void _confirmarFinDeTurno() {
    if (!mounted || !_llamadaActiva || !_escuchando) return;
    _speech.stop();
    final texto = _ultimoTranscript.trim();
    setState(() => _escuchando = false);
    if (texto.isEmpty) {
      _comenzarEscucha();
      return;
    }
    HapticFeedback.lightImpact();
    _enviarMensaje(texto);
  }

  Future<void> _enviarMensaje(String texto) async {
    if (_sessionId == null) return;
    setState(() => _procesando = true);
    try {
      final respuesta = await _api.interviewMessage(sessionId: _sessionId!, mensaje: texto);
      if (!mounted) return;
      setState(() => _procesando = false);
      unawaited(_hablar(respuesta));
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _procesando = false;
          _error = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _procesando = false;
          _error = 'No se pudo enviar tu respuesta';
        });
      }
    }
  }

  Future<void> _finalizar() async {
    if (_sessionId == null) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalizar práctica'),
        content: const Text('¿Terminar la entrevista y ver tus recomendaciones?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Seguir practicando'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: RumboColors.danger),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    setState(() {
      _finalizando = true;
      _llamadaActiva = false;
    });
    _silencioTimer?.cancel();
    await _tts.stop();
    await _speech.stop();
    try {
      final feedback = await _api.interviewFinalizar(_sessionId!);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          RumboPageRoute(builder: (_) => InterviewFeedbackScreen(feedback: feedback)),
        );
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudieron generar las recomendaciones')),
        );
      }
    } finally {
      if (mounted) setState(() => _finalizando = false);
    }
  }

  // -------------------------------------------------------------------------
  // UI
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_sessionId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Práctica de entrevista')),
        body: SafeArea(top: false, child: _buildConfig(context)),
      );
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmarSalida();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _buildLlamada(context),
      ),
    );
  }

  /// Salir con el botón atrás en medio de una práctica pierde la sesión, así
  /// que se confirma igual que al finalizar.
  Future<void> _confirmarSalida() async {
    final salir = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Salir de la práctica'),
        content: const Text('Si salís ahora, se pierde esta sesión y no vas a recibir recomendaciones.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Seguir')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: RumboColors.danger),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (salir == true && mounted) Navigator.of(context).pop();
  }

  Widget _buildConfig(BuildContext context) {
    final esTradicional = _modo == 'tradicional';
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        FadeSlideIn(
          index: 0,
          child: BrandHeader(
            icono: Icons.videocam_outlined,
            titulo: 'Practicá como si fuera real',
            subtitulo: 'La IA te habla en voz alta y vos respondés hablando. '
                'La app detecta sola cuándo terminaste.',
          ),
        ),
        const SizedBox(height: 24),
        const FadeSlideIn(index: 1, child: SectionTitle('¿Qué querés practicar?')),
        const SizedBox(height: 12),
        FadeSlideIn(
          index: 2,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'tradicional', label: Text('Entrevista laboral')),
              ButtonSegment(value: 'freelance', label: Text('Negociar con cliente')),
            ],
            selected: {_modo},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _modo = s.first),
          ),
        ),
        const SizedBox(height: 22),
        FadeSlideIn(
          index: 3,
          child: TextField(
            controller: _sectorCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Sector (opcional)',
              hintText: 'Ej: Marketing digital',
              prefixIcon: Icon(Icons.category_outlined, size: 20),
            ),
          ),
        ),
        const SizedBox(height: 22),
        FadeSlideIn(
          index: 4,
          child: RumboCard(
            color: RumboColors.navyRaised,
            borderColor: RumboColors.navyBright.withValues(alpha: 0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, size: 17, color: RumboColors.navyBright),
                    const SizedBox(width: 9),
                    Text(
                      'Antes de empezar',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(color: RumboColors.navyBright),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final consejo in [
                  'Buscá un lugar en silencio: el micrófono capta todo.',
                  'Hablá pausado y esperá a que la IA termine su turno.',
                  if (esTradicional)
                    'Tené a mano tu experiencia: te va a preguntar por ella.'
                  else
                    'Pensá tu tarifa: la negociación va a llegar ahí.',
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 6, right: 10),
                          child: SizedBox(
                            width: 5,
                            height: 5,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: RumboColors.navyBright,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            consejo,
                            style: const TextStyle(color: RumboColors.textMid, fontSize: 13, height: 1.45),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 18),
          InfoBanner(mensaje: _error!),
        ],
        const SizedBox(height: 24),
        LoadingButton(
          texto: 'Iniciar videollamada',
          textoCargando: 'Conectando...',
          cargando: _iniciando,
          onPressed: _iniciar,
          icono: Icons.videocam_rounded,
        ),
      ],
    );
  }

  Widget _buildLlamada(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildCameraBackground(),
        // Velos arriba y abajo para que los controles blancos se lean sobre
        // cualquier imagen de cámara.
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 220,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xCC000000), Colors.transparent],
              ),
            ),
          ),
        ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 300,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xE6000000)],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              _buildBarraSuperior(),
              const SizedBox(height: 12),
              AiAvatar(
                speaking: _hablando,
                listening: _escuchando,
                thinking: _procesando,
                size: 84,
              ),
              const Spacer(),
              _buildTranscripcion(),
              const SizedBox(height: 16),
              _buildEstado(),
              const SizedBox(height: 20),
              _buildControles(),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBarraSuperior() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          _BotonCircular(
            icono: Icons.arrow_back_rounded,
            onTap: _confirmarSalida,
            color: Colors.white.withValues(alpha: 0.16),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: RumboRadii.pill,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _PuntoEnVivo(),
                const SizedBox(width: 8),
                Text(
                  _modo == 'tradicional' ? 'Entrevista' : 'Negociación',
                  style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Muestra en vivo lo que el reconocedor va entendiendo. Sin esto, el usuario
  /// habla "a ciegas" y no sabe si el micrófono lo está tomando.
  Widget _buildTranscripcion() {
    final visible = _escuchando && _ultimoTranscript.trim().isNotEmpty;
    return AnimatedSize(
      duration: RumboMotion.medium,
      curve: RumboMotion.emphasized,
      child: AnimatedOpacity(
        duration: RumboMotion.fast,
        opacity: visible ? 1 : 0,
        child: visible
            ? Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(RumboRadii.md),
                  border: Border.all(color: RumboColors.success.withValues(alpha: 0.3)),
                ),
                child: SingleChildScrollView(
                  reverse: true,
                  child: Text(
                    _ultimoTranscript,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 14.5, height: 1.45),
                  ),
                ),
              )
            : const SizedBox(width: double.infinity),
      ),
    );
  }

  Widget _buildEstado() {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: RumboMotion.fast,
          child: Text(
            _estadoTexto,
            key: ValueKey(_estadoTexto),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15.5),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12.5),
            ),
          ),
        ],
      ],
    );
  }

  String get _estadoTexto {
    if (_hablando) return 'La IA está hablando...';
    if (_procesando) return 'Pensando tu respuesta...';
    if (_escuchando) return 'Te escucho...';
    return 'Tocá el micrófono para responder';
  }

  Widget _buildControles() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(width: 68),
        const Spacer(),
        _buildBotonMic(),
        const Spacer(),
        SizedBox(
          width: 68,
          child: Center(
            child: _BotonCircular(
              icono: Icons.call_end_rounded,
              onTap: _finalizando ? null : _finalizar,
              color: RumboColors.crimson,
              cargando: _finalizando,
              tamano: 54,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBotonMic() {
    late final IconData icono;
    late final Color color;
    VoidCallback? onTap;

    if (_hablando) {
      icono = Icons.graphic_eq_rounded;
      color = Colors.white.withValues(alpha: 0.18);
      onTap = null;
    } else if (_procesando) {
      icono = Icons.more_horiz_rounded;
      color = Colors.white.withValues(alpha: 0.18);
      onTap = null;
    } else if (_escuchando) {
      icono = Icons.stop_rounded;
      color = RumboColors.success;
      onTap = () {
        _silencioTimer?.cancel();
        _confirmarFinDeTurno();
      };
    } else {
      icono = Icons.mic_rounded;
      color = RumboColors.crimson;
      onTap = _comenzarEscucha;
    }

    return _BotonMic(icono: icono, color: color, onTap: onTap, pulsando: _escuchando);
  }

  Widget _buildCameraBackground() {
    if (_errorCamara != null) {
      return Container(
        color: RumboColors.ink,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off_outlined, color: Colors.white38, size: 34),
            const SizedBox(height: 14),
            Text(
              _errorCamara!,
              style: const TextStyle(color: Colors.white54, fontSize: 13.5, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    final controller = _cameraController;
    if (controller == null || _cameraInitFuture == null) {
      return const ColoredBox(color: RumboColors.ink);
    }
    return FutureBuilder<void>(
      future: _cameraInitFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done || !controller.value.isInitialized) {
          return const ColoredBox(
            color: RumboColors.ink,
            child: Center(child: CircularProgressIndicator(color: Colors.white24)),
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            // Escala para cubrir la pantalla completa sin deformar la imagen.
            var scale = size.aspectRatio * controller.value.aspectRatio;
            if (scale < 1) scale = 1 / scale;
            final esFrontal = controller.description.lensDirection == CameraLensDirection.front;
            Widget preview = CameraPreview(controller);
            if (esFrontal) {
              // Espejo: la cámara frontal se ve invertida respecto de un espejo real.
              preview = Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(math.pi),
                child: preview,
              );
            }
            return ClipRect(
              child: Transform.scale(scale: scale, child: Center(child: preview)),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Controles de la llamada
// ---------------------------------------------------------------------------

class _BotonCircular extends StatelessWidget {
  final IconData icono;
  final VoidCallback? onTap;
  final Color color;
  final bool cargando;
  final double tamano;

  const _BotonCircular({
    required this.icono,
    required this.onTap,
    required this.color,
    this.cargando = false,
    this.tamano = 42,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: tamano,
        height: tamano,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: cargando
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
              )
            : Icon(icono, color: Colors.white, size: tamano * 0.45),
      ),
    );
  }
}

/// Botón de micrófono: mientras escucha emite un halo que late, para que se
/// note de lejos que el turno es tuyo.
class _BotonMic extends StatefulWidget {
  final IconData icono;
  final Color color;
  final VoidCallback? onTap;
  final bool pulsando;

  const _BotonMic({
    required this.icono,
    required this.color,
    required this.onTap,
    required this.pulsando,
  });

  @override
  State<_BotonMic> createState() => _BotonMicState();
}

class _BotonMicState extends State<_BotonMic> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              if (widget.pulsando)
                for (final fase in [0.0, 0.5])
                  Builder(
                    builder: (_) {
                      final t = (_controller.value + fase) % 1.0;
                      return Opacity(
                        opacity: (1 - t) * 0.35,
                        child: Container(
                          width: 74 + t * 44,
                          height: 74 + t * 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.color.withValues(alpha: 0.35),
                          ),
                        ),
                      );
                    },
                  ),
              child!,
            ],
          );
        },
        child: PressableScale(
          onTap: widget.onTap,
          scale: 0.92,
          child: Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.45),
                  blurRadius: 24,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(widget.icono, color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }
}

/// Puntito rojo que parpadea, como el "REC" de una videollamada.
class _PuntoEnVivo extends StatefulWidget {
  const _PuntoEnVivo();

  @override
  State<_PuntoEnVivo> createState() => _PuntoEnVivoState();
}

class _PuntoEnVivoState extends State<_PuntoEnVivo> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(_controller),
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(color: RumboColors.crimsonBright, shape: BoxShape.circle),
      ),
    );
  }
}
