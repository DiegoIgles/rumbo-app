import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../services/api_client.dart';
import '../services/auth_controller.dart';
import '../theme.dart';
import '../widgets/ai_avatar.dart';
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

  Future<void> _iniciarCamara() async {
    try {
      final camaras = await availableCameras();
      if (camaras.isEmpty) {
        setState(() => _errorCamara = 'No se encontró ninguna cámara en este dispositivo.');
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
      if (mounted) setState(() => _errorCamara = 'No se pudo acceder a la cámara. Podés seguir la práctica sin video.');
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
    setState(() {
      _iniciando = true;
      _error = null;
    });
    try {
      final r = await _api.interviewStart(modo: _modo, sector: _sectorCtrl.text.trim().isEmpty ? null : _sectorCtrl.text.trim());
      setState(() {
        _sessionId = r.sessionId;
        _llamadaActiva = true;
      });
      unawaited(_iniciarCamara());
      await _inicializarSpeech();
      unawaited(_hablar(r.mensajeInicial));
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'No se pudo iniciar la práctica');
    } finally {
      if (mounted) setState(() => _iniciando = false);
    }
  }

  Future<void> _hablar(String texto) async {
    setState(() => _hablando = true);
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
        _ultimoTranscript = result.recognizedWords;
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
      setState(() {
        _procesando = false;
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _procesando = false;
        _error = 'No se pudo enviar tu respuesta';
      });
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
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Seguir practicando')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Finalizar')),
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
          MaterialPageRoute(builder: (_) => InterviewFeedbackScreen(feedback: feedback)),
        );
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudieron generar las recomendaciones')));
    } finally {
      if (mounted) setState(() => _finalizando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sessionId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Práctica de entrevista')),
        body: SafeArea(child: _buildConfig(context)),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildLlamada(context),
    );
  }

  Widget _buildConfig(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Es como una videollamada: la IA te va a hablar en voz alta y vos respondés hablando. '
            'La app detecta sola cuándo terminaste de hablar.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 20),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'tradicional', label: Text('Entrevista laboral')),
              ButtonSegment(value: 'freelance', label: Text('Negociación con cliente')),
            ],
            selected: {_modo},
            onSelectionChanged: (s) => setState(() => _modo = s.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _sectorCtrl,
            decoration: const InputDecoration(labelText: 'Sector (opcional)', hintText: 'Ej: Marketing digital'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Color(0xFFDC2626))),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _iniciando ? null : _iniciar,
              icon: _iniciando
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.videocam_outlined),
              label: Text(_iniciando ? 'Conectando...' : 'Iniciar videollamada con la IA'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLlamada(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildCameraBackground(),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 260,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                TextButton.icon(
                  onPressed: _finalizando ? null : _finalizar,
                  icon: _finalizando
                      ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.call_end, color: Colors.white, size: 18),
                  label: const Text('Finalizar', style: TextStyle(color: Colors.white)),
                  style: TextButton.styleFrom(backgroundColor: Colors.black45),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 90,
          left: 0,
          right: 0,
          child: Center(child: AiAvatar(speaking: _hablando, size: 88)),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 28,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Text(_estadoTexto, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
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
                const SizedBox(height: 18),
                _buildBotonMic(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String get _estadoTexto {
    if (_hablando) return 'La IA está hablando...';
    if (_procesando) return 'Pensando tu respuesta...';
    if (_escuchando) return 'Te escucho...';
    return 'Tocá el micrófono para responder';
  }

  Widget _buildBotonMic() {
    IconData icon;
    Color color;
    VoidCallback? onTap;
    if (_hablando) {
      icon = Icons.graphic_eq;
      color = Colors.white24;
      onTap = null;
    } else if (_procesando) {
      icon = Icons.more_horiz;
      color = Colors.white24;
      onTap = null;
    } else if (_escuchando) {
      icon = Icons.mic;
      color = const Color(0xFFDC2626);
      onTap = () {
        _silencioTimer?.cancel();
        _confirmarFinDeTurno();
      };
    } else {
      icon = Icons.mic_none;
      color = rumboPrimary;
      onTap = _comenzarEscucha;
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildCameraBackground() {
    if (_errorCamara != null) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Text(_errorCamara!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
      );
    }
    final controller = _cameraController;
    if (controller == null || _cameraInitFuture == null) {
      return const ColoredBox(color: Colors.black);
    }
    return FutureBuilder<void>(
      future: _cameraInitFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done || !controller.value.isInitialized) {
          return const ColoredBox(color: Colors.black, child: Center(child: CircularProgressIndicator(color: Colors.white38)));
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            var scale = size.aspectRatio * controller.value.aspectRatio;
            if (scale < 1) scale = 1 / scale;
            final esFrontal = controller.description.lensDirection == CameraLensDirection.front;
            Widget preview = CameraPreview(controller);
            if (esFrontal) {
              preview = Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(math.pi),
                child: preview,
              );
            }
            return ClipRect(
              child: Transform.scale(
                scale: scale,
                child: Center(child: preview),
              ),
            );
          },
        );
      },
    );
  }
}
