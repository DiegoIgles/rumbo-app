import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/experiencia.dart';
import '../services/api_client.dart';
import '../services/auth_controller.dart';
import '../theme.dart';
import '../utils/formato.dart';
import '../widgets/ui_kit.dart';

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
      _error = null;
    });
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_fechaInicio == null) {
      setState(() => _error = 'Elegí la fecha de inicio');
      return;
    }
    if (!_trabajoActual && _fechaFin == null) {
      setState(() => _error = 'Elegí la fecha de fin, o marcá que trabajás ahí actualmente');
      return;
    }
    if (!_trabajoActual && _fechaFin!.isBefore(_fechaInicio!)) {
      setState(() => _error = 'La fecha de fin no puede ser anterior a la de inicio');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final api = context.read<AuthController>().api;
      final referencia = _referenciaCtrl.text.trim();
      if (_esEdicion) {
        await api.editarExperiencia(
          id: widget.experiencia!.id,
          puesto: _puestoCtrl.text.trim(),
          empresa: _empresaCtrl.text.trim(),
          fechaInicio: _fechaInicio!,
          fechaFin: _trabajoActual ? null : _fechaFin,
          referencia: referencia.isEmpty ? null : referencia,
        );
      } else {
        await api.crearExperiencia(
          puesto: _puestoCtrl.text.trim(),
          empresa: _empresaCtrl.text.trim(),
          fechaInicio: _fechaInicio!,
          fechaFin: _trabajoActual ? null : _fechaFin,
          referencia: referencia.isEmpty ? null : referencia,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo guardar la experiencia');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_esEdicion ? 'Editar experiencia' : 'Agregar experiencia')),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              if (_error != null) ...[
                InfoBanner(mensaje: _error!),
                const SizedBox(height: 18),
              ],
              FadeSlideIn(
                index: 0,
                child: TextFormField(
                  controller: _puestoCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Puesto / cargo',
                    hintText: 'Ej: Asistente de marketing',
                    prefixIcon: Icon(Icons.badge_outlined, size: 20),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresá el puesto' : null,
                ),
              ),
              const SizedBox(height: 16),
              FadeSlideIn(
                index: 1,
                child: TextFormField(
                  controller: _empresaCtrl,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Empresa / lugar',
                    prefixIcon: Icon(Icons.business_outlined, size: 20),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresá la empresa' : null,
                ),
              ),
              const SizedBox(height: 24),
              const FadeSlideIn(index: 2, child: SectionTitle('¿Cuándo fue?')),
              const SizedBox(height: 14),
              FadeSlideIn(
                index: 3,
                child: _SelectorFecha(
                  etiqueta: 'Desde',
                  fecha: _fechaInicio,
                  onTap: () => _elegirFecha(esInicio: true),
                ),
              ),
              const SizedBox(height: 12),
              FadeSlideIn(
                index: 4,
                child: RumboCard(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: CheckboxListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _trabajoActual,
                    title: const Text('Trabajo acá actualmente', style: TextStyle(fontSize: 14.5)),
                    onChanged: (v) => setState(() {
                      _trabajoActual = v ?? true;
                      _error = null;
                    }),
                  ),
                ),
              ),
              AnimatedSize(
                duration: RumboMotion.medium,
                curve: RumboMotion.emphasized,
                alignment: Alignment.topCenter,
                child: _trabajoActual
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _SelectorFecha(
                          etiqueta: 'Hasta',
                          fecha: _fechaFin,
                          onTap: () => _elegirFecha(esInicio: false),
                        ),
                      ),
              ),
              const SizedBox(height: 24),
              FadeSlideIn(
                index: 5,
                child: TextFormField(
                  controller: _referenciaCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Referencia (opcional)',
                    hintText: 'Ej: Nombre del jefe/a y contacto',
                    prefixIcon: Icon(Icons.contact_phone_outlined, size: 20),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              LoadingButton(
                texto: 'Guardar',
                textoCargando: 'Guardando...',
                cargando: _guardando,
                onPressed: _guardar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectorFecha extends StatelessWidget {
  final String etiqueta;
  final DateTime? fecha;
  final VoidCallback onTap;

  const _SelectorFecha({required this.etiqueta, required this.fecha, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final elegida = fecha != null;
    return RumboCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      borderColor: elegida ? RumboColors.crimsonBright.withValues(alpha: 0.35) : null,
      child: Row(
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 18,
            color: elegida ? RumboColors.crimsonBright : RumboColors.textLow,
          ),
          const SizedBox(width: 13),
          Text(etiqueta, style: const TextStyle(color: RumboColors.textMid, fontSize: 14)),
          const Spacer(),
          Text(
            elegida ? fechaCorta(fecha!) : 'Elegir fecha',
            style: TextStyle(
              color: elegida ? RumboColors.textHigh : RumboColors.textLow,
              fontSize: 14,
              fontWeight: elegida ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded, size: 18, color: RumboColors.textLow),
        ],
      ),
    );
  }
}
