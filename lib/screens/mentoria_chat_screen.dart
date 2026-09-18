import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/mentoria.dart';
import '../services/api_client.dart';
import '../services/auth_controller.dart';
import '../theme.dart';

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
      setState(() => _mensajes = mensajes);
      _scrollToBottom();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'No se pudieron cargar los mensajes');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _enviar() async {
    final texto = _mensajeCtrl.text.trim();
    if (texto.isEmpty) return;
    setState(() => _enviando = true);
    try {
      final mensaje = await context.read<AuthController>().api.enviarMensajeMentoria(widget.mentoria.id, texto);
      setState(() {
        _mensajes = [..._mensajes, mensaje];
        _mensajeCtrl.clear();
      });
      _scrollToBottom();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo enviar el mensaje')));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final otraPersona =
        widget.mentoria.mentorId == _miUserId ? widget.mentoria.jovenNombre : widget.mentoria.mentorNombre;
    return Scaffold(
      appBar: AppBar(title: Text(otraPersona)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _mensajes.isEmpty
                          ? const Center(child: Text('Todavía no hay mensajes. ¡Escribí el primero!'))
                          : ListView.builder(
                              controller: _scrollCtrl,
                              padding: const EdgeInsets.all(16),
                              itemCount: _mensajes.length,
                              itemBuilder: (context, i) => _MensajeBubble(mensaje: _mensajes[i], esMio: _mensajes[i].remitenteId == _miUserId),
                            ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _mensajeCtrl,
                      decoration: const InputDecoration(hintText: 'Escribí un mensaje...'),
                      enabled: !_enviando,
                      onSubmitted: (_) => _enviando ? null : _enviar(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _enviando ? null : _enviar,
                    icon: _enviando
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MensajeBubble extends StatelessWidget {
  final MentoriaMensaje mensaje;
  final bool esMio;

  const _MensajeBubble({required this.mensaje, required this.esMio});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: esMio ? rumboPrimary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(mensaje.texto, style: TextStyle(color: esMio ? Colors.white : Colors.black87)),
      ),
    );
  }
}
