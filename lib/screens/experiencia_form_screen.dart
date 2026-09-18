import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/experiencia.dart';
import '../services/api_client.dart';
import '../services/auth_controller.dart';

class ExperienciaFormScreen extends StatefulWidget {
  /// Si es null, se está creando una experiencia nueva; si no, se edita esta.
  final Experiencia? experiencia;

  const ExperienciaFormScreen({super.key, this.experiencia});

  @override
  State<ExperienciaFormScreen> createState() => _ExperienciaFormScreenState();
}

class _ExperienciaFormScreenState extends State<ExperienciaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _puestoCtrl = TextEditingController();
  final _empresaCtrl = TextEditingController();
  final _referenciaCtrl = TextEditingController();
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  bool _trabajoActual = true;
  bool _guardando = false;
  String? _error;

  bool get _esEdicion => widget.experiencia != null;

  @override
  void initState() {
    super.initState();
    final e = widget.experiencia;
    if (e != null) {
      _puestoCtrl.text = e.puesto;
      _empresaCtrl.text = e.empresa;
      _referenciaCtrl.text = e.referencia ?? '';
      _fechaInicio = e.fechaInicio;
      _fechaFin = e.fechaFin;
      _trabajoActual = e.esActual;
    }
  }

  @override
  void dispose() {
    _puestoCtrl.dispose();
    _empresaCtrl.dispose();
    _referenciaCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha({required bool esInicio}) async {
    final ahora = DateTime.now();
    final inicial = esInicio ? (_fechaInicio ?? ahora) : (_fechaFin ?? _fechaInicio ?? ahora);
    final elegida = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(1970),
      lastDate: ahora,
    );
    if (elegida == null) return;
    setState(() {
      if (esInicio) {
        _fechaInicio = elegida;
      } else {
        _fechaFin = elegida;
      }
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaInicio == null) {
      setState(() => _error = 'Elegí la fecha de inicio');
      return;
    }
    if (!_trabajoActual && _fechaFin == null) {
      setState(() => _error = 'Elegí la fecha de fin, o marcá que trabajás ahí actualmente');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final api = context.read<AuthController>().api;
      if (_esEdicion) {
        await api.editarExperiencia(
          id: widget.experiencia!.id,
          puesto: _puestoCtrl.text.trim(),
          empresa: _empresaCtrl.text.trim(),
          fechaInicio: _fechaInicio!,
          fechaFin: _trabajoActual ? null : _fechaFin,
          referencia: _referenciaCtrl.text.trim().isEmpty ? null : _referenciaCtrl.text.trim(),
        );
      } else {
        await api.crearExperiencia(
          puesto: _puestoCtrl.text.trim(),
          empresa: _empresaCtrl.text.trim(),
          fechaInicio: _fechaInicio!,
          fechaFin: _trabajoActual ? null : _fechaFin,
          referencia: _referenciaCtrl.text.trim().isEmpty ? null : _referenciaCtrl.text.trim(),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'No se pudo guardar la experiencia');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  String _formatearFecha(DateTime? d) {
    if (d == null) return 'Elegir fecha';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_esEdicion ? 'Editar experiencia' : 'Agregar experiencia')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10)),
                    child: Text(_error!, style: const TextStyle(color: Color(0xFFDC2626))),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _puestoCtrl,
                  decoration: const InputDecoration(labelText: 'Puesto / cargo'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresá el puesto' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _empresaCtrl,
                  decoration: const InputDecoration(labelText: 'Empresa / lugar'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresá la empresa' : null,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _elegirFecha(esInicio: true),
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text('Desde: ${_formatearFecha(_fechaInicio)}'),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _trabajoActual,
                  title: const Text('Trabajo acá actualmente'),
                  onChanged: (v) => setState(() => _trabajoActual = v ?? true),
                ),
                if (!_trabajoActual) ...[
                  OutlinedButton.icon(
                    onPressed: () => _elegirFecha(esInicio: false),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text('Hasta: ${_formatearFecha(_fechaFin)}'),
                  ),
                  const SizedBox(height: 16),
                ] else
                  const SizedBox(height: 4),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _referenciaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Referencia (opcional)',
                    hintText: 'Ej: Nombre del jefe/a y contacto',
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _guardando ? null : _guardar,
                    child: _guardando
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
