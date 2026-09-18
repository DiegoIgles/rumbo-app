import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../services/auth_controller.dart';

class MentoriaGrupalFormScreen extends StatefulWidget {
  const MentoriaGrupalFormScreen({super.key});

  @override
  State<MentoriaGrupalFormScreen> createState() => _MentoriaGrupalFormScreenState();
}

class _MentoriaGrupalFormScreenState extends State<MentoriaGrupalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _cupoCtrl = TextEditingController(text: '10');
  final _meetLinkCtrl = TextEditingController();
  DateTime? _fecha;
  TimeOfDay? _hora;
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _cupoCtrl.dispose();
    _meetLinkCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final ahora = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha ?? ahora,
      firstDate: ahora,
      lastDate: ahora.add(const Duration(days: 365)),
    );
    if (elegida != null) setState(() => _fecha = elegida);
  }

  Future<void> _elegirHora() async {
    final elegida = await showTimePicker(context: context, initialTime: _hora ?? TimeOfDay.now());
    if (elegida != null) setState(() => _hora = elegida);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fecha == null || _hora == null) {
      setState(() => _error = 'Elegí la fecha y la hora de la sesión');
      return;
    }
    final fechaHora = DateTime(_fecha!.year, _fecha!.month, _fecha!.day, _hora!.hour, _hora!.minute);

    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await context.read<AuthController>().api.crearMentoriaGrupal(
            titulo: _tituloCtrl.text.trim(),
            descripcion: _descripcionCtrl.text.trim(),
            cupoMaximo: int.parse(_cupoCtrl.text.trim()),
            meetLink: _meetLinkCtrl.text.trim(),
            fechaHora: fechaHora,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'No se pudo publicar la mentoría grupal');
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
      appBar: AppBar(title: const Text('Nueva mentoría grupal')),
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
                  controller: _tituloCtrl,
                  decoration: const InputDecoration(labelText: 'Título', hintText: 'Ej: Cómo armar tu primer CV'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresá un título' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descripcionCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Descripción', alignLabelWithHint: true),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Contá de qué va a tratar' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cupoCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Cantidad de estudiantes que aceptará'),
                  validator: (v) {
                    final n = int.tryParse(v?.trim() ?? '');
                    if (n == null || n < 1) return 'Ingresá un número mayor a 0';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _meetLinkCtrl,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(labelText: 'Link de Meet', hintText: 'https://meet.google.com/...'),
                  validator: (v) {
                    final uri = Uri.tryParse(v?.trim() ?? '');
                    if (uri == null || !uri.isAbsolute) return 'Pegá un link válido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _elegirFecha,
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(_formatearFecha(_fecha)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _elegirHora,
                        icon: const Icon(Icons.schedule, size: 16),
                        label: Text(_hora == null ? 'Elegir hora' : _hora!.format(context)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _guardando ? null : _guardar,
                    child: _guardando
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Publicar mentoría grupal'),
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
