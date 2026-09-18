import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_constants.dart';
import '../services/api_client.dart';
import '../services/auth_controller.dart';
import '../theme.dart';
import '../widgets/ui_kit.dart';

class MentorProfileScreen extends StatefulWidget {
  const MentorProfileScreen({super.key});

  @override
  State<MentorProfileScreen> createState() => _MentorProfileScreenState();
}

class _MentorProfileScreenState extends State<MentorProfileScreen> {
  final _bioCtrl = TextEditingController();
  final _disponibilidadCtrl = TextEditingController();
  String _areaExpertise = areas.first;
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
      // El backend no expone "mi perfil de mentor", así que se busca el propio
      // dentro del listado público por id de usuario.
      final propios = todos.where((m) => m.userId == auth.user?.id);
      if (propios.isNotEmpty) {
        final propio = propios.first;
        if (mounted) {
          setState(() {
            _areaExpertise = areas.contains(propio.areaExpertise) ? propio.areaExpertise : areas.first;
            _bioCtrl.text = propio.bio ?? '';
            _disponibilidadCtrl.text = propio.disponibilidad ?? '';
          });
        }
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo cargar tu perfil de mentor');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _guardando = true;
      _error = null;
      _mensajeGuardado = null;
    });
    try {
      final bio = _bioCtrl.text.trim();
      final disponibilidad = _disponibilidadCtrl.text.trim();
      await context.read<AuthController>().api.upsertMentorProfile(
            areaExpertise: _areaExpertise,
            bio: bio.isEmpty ? null : bio,
            disponibilidad: disponibilidad.isEmpty ? null : disponibilidad,
          );
      if (mounted) {
        setState(() => _mensajeGuardado =
            'Tu perfil está publicado. Ya te pueden encontrar los jóvenes que buscan mentoría.');
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo guardar tu perfil de mentor');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil de mentor')),
      body: SafeArea(
        top: false,
        child: _loading
            ? const SkeletonList(cantidad: 3)
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  FadeSlideIn(
                    index: 0,
                    child: BrandHeader(
                      icono: Icons.volunteer_activism_outlined,
                      titulo: 'Así te van a ver',
                      subtitulo: 'Este es el perfil que aparece cuando alguien busca mentores.',
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_error != null) ...[
                    InfoBanner(mensaje: _error!),
                    const SizedBox(height: 16),
                  ],
                  if (_mensajeGuardado != null) ...[
                    InfoBanner(mensaje: _mensajeGuardado!, tono: BannerTono.exito),
                    const SizedBox(height: 16),
                  ],
                  FadeSlideIn(
                    index: 1,
                    child: DropdownButtonFormField<String>(
                      key: ValueKey(_areaExpertise),
                      initialValue: _areaExpertise,
                      isExpanded: true,
                      dropdownColor: RumboColors.surfaceRaised,
                      decoration: const InputDecoration(
                        labelText: 'Área de expertise',
                        prefixIcon: Icon(Icons.category_outlined, size: 20),
                      ),
                      items: areas.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                      onChanged: (v) => setState(() => _areaExpertise = v ?? _areaExpertise),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeSlideIn(
                    index: 2,
                    child: TextField(
                      controller: _bioCtrl,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        hintText: 'Contá tu experiencia y en qué podés ayudar.',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeSlideIn(
                    index: 3,
                    child: TextField(
                      controller: _disponibilidadCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Disponibilidad',
                        hintText: 'Ej: Sábados por la mañana',
                        prefixIcon: Icon(Icons.schedule_rounded, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  LoadingButton(
                    texto: 'Guardar perfil',
                    textoCargando: 'Guardando...',
                    cargando: _guardando,
                    onPressed: _guardar,
                  ),
                ],
              ),
      ),
    );
  }
}
