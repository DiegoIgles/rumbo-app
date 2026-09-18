import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/mentoria.dart';
import '../services/api_client.dart';
import '../services/auth_controller.dart';
import '../theme.dart';
import '../utils/formato.dart';
import '../widgets/ui_kit.dart';

class MentoriaChatScreen extends StatefulWidget {
  final Mentoria mentoria;

  const MentoriaChatScreen({super.key, required this.mentoria});

  @override
  State<MentoriaChatScreen> createState() => _MentoriaChatScreenState();
}

class _MentoriaChatScreenState extends State<MentoriaChatScreen> {
  final _mensajeCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<MentoriaMensaje> _mensajes = [];
  bool _loading = true;
  bool _enviando = false;
  String? _error;
  String? _miUserId;

  @override
  void initState() {
    super.initState();
    _miUserId = context.read<AuthController>().user?.id;
    _cargar();
  }

  @override
  void dispose() {
    _mensajeCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final mensajes = await context.read<AuthController>().api.mensajesMentoria(widget.mentoria.id);
      if (!mounted) return;
      setState(() => _mensajes = mensajes);
      _scrollToBottom();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudieron cargar los mensajes');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _enviar() async {
    final texto = _mensajeCtrl.text.trim();
    if (texto.isEmpty) return;
    setState(() => _enviando = true);
    try {
      final mensaje = await context.read<AuthController>().api.enviarMensajeMentoria(
            widget.mentoria.id,
            texto,
          );
      if (!mounted) return;
      setState(() {
        _mensajes = [..._mensajes, mensaje];
        _mensajeCtrl.clear();
      });
      _scrollToBottom();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo enviar el mensaje')),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: RumboMotion.medium,
          curve: RumboMotion.decelerate,
        );
      }
    });
  }

  String get _otraPersona =>
      widget.mentoria.mentorId == _miUserId ? widget.mentoria.jovenNombre : widget.mentoria.mentorNombre;

  String get _iniciales {
    final partes = _otraPersona.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return (partes.first.substring(0, 1) + partes[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                gradient: RumboColors.navyGradient,
                shape: BoxShape.circle,
              ),
              child: Text(
                _iniciales,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _otraPersona,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const Text(
                    'Mentoría activa',
                    style: TextStyle(color: RumboColors.success, fontSize: 11.5, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh_rounded, size: 21),
            onPressed: _loading ? null : _cargar,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(child: _buildLista()),
            _buildComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildLista() {
    if (_loading) return const SkeletonList(cantidad: 3);
    if (_error != null) {
      return StatusView(
        icono: Icons.cloud_off_rounded,
        titulo: 'No se pudo conectar',
        detalle: _error,
        textoAccion: 'Reintentar',
        onAccion: _cargar,
        esError: true,
      );
    }
    if (_mensajes.isEmpty) {
      return const StatusView(
        icono: Icons.chat_bubble_outline_rounded,
        titulo: 'Todavía no hay mensajes',
        detalle: '¡Escribí el primero y rompé el hielo!',
      );
    }
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _mensajes.length,
      itemBuilder: (context, i) {
        final m = _mensajes[i];
        final anterior = i > 0 ? _mensajes[i - 1] : null;
        return _MensajeBubble(
          mensaje: m,
          esMio: m.remitenteId == _miUserId,
          // Encadena burbujas del mismo remitente: se agrupan visualmente en
          // vez de repetir el mismo espaciado entre todas.
          encadenado: anterior != null && anterior.remitenteId == m.remitenteId,
        );
      },
    );
  }

  Widget _buildComposer() {
    return Container(
      decoration: const BoxDecoration(
        color: RumboColors.ink,
        border: Border(top: BorderSide(color: RumboColors.outlineSoft)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _mensajeCtrl,
              enabled: !_enviando,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _enviando ? null : _enviar(),
              decoration: const InputDecoration(
                hintText: 'Escribí un mensaje...',
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              ),
            ),
          ),
          const SizedBox(width: 10),
          PressableScale(
            onTap: _enviando ? null : _enviar,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _enviando ? RumboColors.surfaceHigh : RumboColors.crimson,
                shape: BoxShape.circle,
              ),
              child: _enviando
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _MensajeBubble extends StatelessWidget {
  final MentoriaMensaje mensaje;
  final bool esMio;
  final bool encadenado;

  const _MensajeBubble({
    required this.mensaje,
    required this.esMio,
    required this.encadenado,
  });

  @override
  Widget build(BuildContext context) {
    final radio = Radius.circular(RumboRadii.md);
    return Align(
      alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(top: encadenado ? 4 : 12),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.76),
        decoration: BoxDecoration(
          color: esMio ? RumboColors.crimson : RumboColors.surfaceRaised,
          border: esMio ? null : Border.all(color: RumboColors.outline),
          borderRadius: BorderRadius.only(
            topLeft: radio,
            topRight: radio,
            bottomLeft: esMio ? radio : const Radius.circular(4),
            bottomRight: esMio ? const Radius.circular(4) : radio,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              mensaje.texto,
              style: TextStyle(
                color: esMio ? Colors.white : RumboColors.textHigh,
                fontSize: 14.5,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              haceCuantoIso(mensaje.fecha),
              style: TextStyle(
                color: esMio ? Colors.white70 : RumboColors.textLow,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
