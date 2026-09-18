import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_constants.dart';
import '../models/experiencia.dart';
import '../models/profile.dart';
import '../services/api_client.dart';
import '../services/auth_controller.dart';
import '../theme.dart';
import 'experiencia_form_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => ProfileTabState();
}

class ProfileTabState extends State<ProfileTab> {
  final _edadCtrl = TextEditingController();
  String? _sectorInteres;
  String? _nivelExperiencia;
  String _rutaPreferida = 'ambas';

  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _mensajeGuardado;

  List<Experiencia>? _experiencias;
  bool _cargandoExperiencia = true;
  String? _errorExperiencia;

  @override
  void initState() {
    super.initState();
    _load();
    _cargarExperiencia();
  }

  @override
  void dispose() {
    _edadCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await context.read<AuthController>().api.getProfile();
      if (profile != null) {
        _edadCtrl.text = profile.edad?.toString() ?? '';
        _sectorInteres = areas.contains(profile.sectorInteres) ? profile.sectorInteres : null;
        _nivelExperiencia = nivelesExperiencia.contains(profile.nivelExperiencia) ? profile.nivelExperiencia : null;
        _rutaPreferida = profile.rutaPreferida;
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cargarExperiencia() async {
    setState(() {
      _cargandoExperiencia = true;
      _errorExperiencia = null;
    });
    try {
      final experiencias = await context.read<AuthController>().api.listarExperiencia();
      setState(() => _experiencias = experiencias);
    } on ApiException catch (e) {
      setState(() => _errorExperiencia = e.message);
    } finally {
      if (mounted) setState(() => _cargandoExperiencia = false);
    }
  }

  Future<void> _abrirFormExperiencia({Experiencia? experiencia}) async {
    final guardado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ExperienciaFormScreen(experiencia: experiencia)),
    );
    if (guardado == true) _cargarExperiencia();
  }

  Future<void> _eliminarExperiencia(Experiencia experiencia) async {
    try {
      await context.read<AuthController>().api.eliminarExperiencia(experiencia.id);
      _cargarExperiencia();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo eliminar')));
    }
  }

  Future<void> _confirmarEliminarExperiencia(Experiencia experiencia) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar experiencia'),
        content: Text('¿Eliminar "${experiencia.puesto}" en ${experiencia.empresa}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmar == true) _eliminarExperiencia(experiencia);
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _mensajeGuardado = null;
      _error = null;
    });
    try {
      await context.read<AuthController>().api.upsertProfile(
            AppProfile(
              edad: int.tryParse(_edadCtrl.text),
              sectorInteres: _sectorInteres,
              nivelExperiencia: _nivelExperiencia,
              rutaPreferida: _rutaPreferida,
            ),
          );
      setState(() => _mensajeGuardado = 'Perfil actualizado.');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => context.read<AuthController>().logout(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(auth.user?.nombre ?? '', style: Theme.of(context).textTheme.titleLarge),
                  Text(auth.user?.email ?? '', style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 24),
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
                  TextField(
                    controller: _edadCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Edad'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    key: ValueKey('sector-$_sectorInteres'),
                    initialValue: _sectorInteres,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Sector de interés'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Sin definir')),
                      ...areas.map((a) => DropdownMenuItem(value: a, child: Text(a))),
                    ],
                    onChanged: (v) => setState(() => _sectorInteres = v),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    key: ValueKey('nivel-$_nivelExperiencia'),
                    initialValue: _nivelExperiencia,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Nivel de experiencia'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Sin definir')),
                      ...nivelesExperiencia.map((n) => DropdownMenuItem(value: n, child: Text(n))),
                    ],
                    onChanged: (v) => setState(() => _nivelExperiencia = v),
                  ),
                  const SizedBox(height: 16),
                  Text('Ruta preferida', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: rutaLabels.entries
                        .map((e) => ButtonSegment(value: e.key, label: Text(e.value, style: const TextStyle(fontSize: 12))))
                        .toList(),
                    selected: {_rutaPreferida},
                    onSelectionChanged: (s) => setState(() => _rutaPreferida = s.first),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Guardar cambios'),
                    ),
                  ),
                  const SizedBox(height: 36),
                  _buildExperienciaSection(context),
                ],
              ),
            ),
    );
  }

  Widget _buildExperienciaSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Experiencia laboral', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            TextButton.icon(
              onPressed: () => _abrirFormExperiencia(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar'),
            ),
          ],
        ),
        const Text(
          'Si ya trabajaste antes, contá en qué y cuándo.',
          style: TextStyle(color: Colors.black54, fontSize: 13),
        ),
        const SizedBox(height: 12),
        if (_cargandoExperiencia) const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
        if (!_cargandoExperiencia && _errorExperiencia != null)
          Text(_errorExperiencia!, style: const TextStyle(color: Color(0xFFDC2626))),
        if (!_cargandoExperiencia && _errorExperiencia == null && (_experiencias?.isEmpty ?? true))
          const Text('Todavía no agregaste experiencia laboral.', style: TextStyle(color: Colors.black54)),
        if (!_cargandoExperiencia && _experiencias != null && _experiencias!.isNotEmpty)
          ..._experiencias!.map((e) => _ExperienciaCard(
                experiencia: e,
                onEdit: () => _abrirFormExperiencia(experiencia: e),
                onDelete: () => _confirmarEliminarExperiencia(e),
              )),
      ],
    );
  }
}

class _ExperienciaCard extends StatelessWidget {
  final Experiencia experiencia;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExperienciaCard({required this.experiencia, required this.onEdit, required this.onDelete});

  String _mes(DateTime d) {
    const meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${meses[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final rango = experiencia.esActual
        ? '${_mes(experiencia.fechaInicio)} — Actualidad'
        : '${_mes(experiencia.fechaInicio)} — ${_mes(experiencia.fechaFin!)}';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(backgroundColor: rumboPrimary.withValues(alpha: 0.12), child: Icon(Icons.work_outline, color: rumboPrimary)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(experiencia.puesto, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(experiencia.empresa, style: const TextStyle(color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(rango, style: const TextStyle(color: Colors.black54, fontSize: 12.5)),
                  if (experiencia.referencia != null && experiencia.referencia!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Referencia: ${experiencia.referencia}', style: const TextStyle(color: Colors.black54, fontSize: 12.5)),
                  ],
                ],
              ),
            ),
            IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: onEdit),
            IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFDC2626)), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}
