import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_constants.dart';
import '../services/api_client.dart';
import '../services/auth_controller.dart';

class MentorProfileScreen extends StatefulWidget {
  const MentorProfileScreen({super.key});

  @override
  State<MentorProfileScreen> createState() => _MentorProfileScreenState();
}

class _MentorProfileScreenState extends State<MentorProfileScreen> {
  final _bioCtrl = TextEditingController();
  final _disponibilidadCtrl = TextEditingController();
  String _areaExpertise = areas[0];
  bool _loading = true;
  bool _guardando = false;
  String? _error;
  String? _mensajeGuardado;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _disponibilidadCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthController>();
      final todos = await auth.api.mentores();
      final propio = todos.where((m) => m.userId == auth.user?.id).firstOrNull;
      if (propio != null) {
        setState(() {
          _areaExpertise = areas.contains(propio.areaExpertise) ? propio.areaExpertise : areas[0];
          _bioCtrl.text = propio.bio ?? '';
          _disponibilidadCtrl.text = propio.disponibilidad ?? '';
        });
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _guardar() async {
    setState(() {
      _guardando = true;
      _error = null;
      _mensajeGuardado = null;
    });
    try {
      await context.read<AuthController>().api.upsertMentorProfile(
            areaExpertise: _areaExpertise,
            bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
            disponibilidad: _disponibilidadCtrl.text.trim().isEmpty ? null : _disponibilidadCtrl.text.trim(),
          );
      setState(() => _mensajeGuardado = 'Tu perfil de mentor está publicado. Ya te pueden encontrar los jóvenes.');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'No se pudo guardar tu perfil de mentor');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil de mentor')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Este es el perfil que ven los jóvenes cuando buscan mentores para pedir acompañamiento.',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10)),
                      child: Text(_error!, style: const TextStyle(color: Color(0xFFDC2626))),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_mensajeGuardado != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(10)),
                      child: Text(_mensajeGuardado!, style: const TextStyle(color: Color(0xFF059669))),
                    ),
                    const SizedBox(height: 16),
                  ],
                  DropdownButtonFormField<String>(
                    key: ValueKey(_areaExpertise),
                    initialValue: _areaExpertise,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Área de expertise'),
                    items: areas.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                    onChanged: (v) => setState(() => _areaExpertise = v ?? _areaExpertise),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _bioCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      hintText: 'Contá tu experiencia y en qué podés ayudar.',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _disponibilidadCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Disponibilidad',
                      hintText: 'Ej: Sábados por la mañana',
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _guardando ? null : _guardar,
                      child: _guardando
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Guardar perfil'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
