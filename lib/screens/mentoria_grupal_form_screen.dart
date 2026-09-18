import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../services/auth_controller.dart';
import '../theme.dart';
import '../utils/formato.dart';
import '../widgets/ui_kit.dart';

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
    if (elegida != null) {
      setState(() {
        _fecha = elegida;
        _error = null;
      });
    }
  }

  Future<void> _elegirHora() async {
    final elegida = await showTimePicker(context: context, initialTime: _hora ?? TimeOfDay.now());
    if (elegida != null) {
      setState(() {
        _hora = elegida;
        _error = null;
      });
    }
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_fecha == null || _hora == null) {
      setState(() => _error = 'Elegí la fecha y la hora de la sesión');
      return;
    }
    final fechaHoraSesion = DateTime(
      _fecha!.year,
      _fecha!.month,
      _fecha!.day,
      _hora!.hour,
      _hora!.minute,
    );

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
            fechaHora: fechaHoraSesion,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo publicar la mentoría grupal');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva sesión grupal')),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              FadeSlideIn(
                index: 0,
                child: BrandHeader(
                  icono: Icons.groups_outlined,
                  titulo: 'Abrí una sesión',
                  subtitulo: 'Publicá una charla grupal con cupo limitado y link de Meet.',
                ),
              ),
              const SizedBox(height: 24),
              if (_error != null) ...[
                InfoBanner(mensaje: _error!),
                const SizedBox(height: 16),
              ],
              FadeSlideIn(
                index: 1,
                child: TextFormField(
                  controller: _tituloCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    hintText: 'Ej: Cómo armar tu primer CV',
                    prefixIcon: Icon(Icons.title_rounded, size: 20),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresá un título' : null,
                ),
              ),
              const SizedBox(height: 16),
              FadeSlideIn(
                index: 2,
                child: TextFormField(
                  controller: _descripcionCtrl,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    hintText: 'Contá de qué va a tratar la sesión.',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Contá de qué va a tratar' : null,
                ),
              ),
              const SizedBox(height: 16),
              FadeSlideIn(
                index: 3,
                child: TextFormField(
                  controller: _cupoCtrl,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Cupo máximo',
                    helperText: 'Cuántas personas podés atender bien en una sesión',
                    helperStyle: TextStyle(color: RumboColors.textLow, fontSize: 12),
                    prefixIcon: Icon(Icons.people_outline_rounded, size: 20),
                  ),
                  validator: (v) {
                    final n = int.tryParse(v?.trim() ?? '');
                    if (n == null || n < 1) return 'Ingresá un número mayor a 0';
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              FadeSlideIn(
                index: 4,
                child: TextFormField(
                  controller: _meetLinkCtrl,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Link de Meet',
                    hintText: 'https://meet.google.com/...',
                    prefixIcon: Icon(Icons.videocam_outlined, size: 20),
                  ),
                  validator: (v) {
                    final uri = Uri.tryParse(v?.trim() ?? '');
                    if (uri == null || !uri.isAbsolute) return 'Pegá un link válido';
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 24),
              const FadeSlideIn(index: 5, child: SectionTitle('¿Cuándo?')),
              const SizedBox(height: 14),
              FadeSlideIn(
                index: 6,
                child: Row(
                  children: [
                    Expanded(
                      child: _BotonFechaHora(
                        icono: Icons.calendar_today_outlined,
                        texto: _fecha == null ? 'Elegir fecha' : fechaCorta(_fecha!),
                        elegido: _fecha != null,
                        onTap: _elegirFecha,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _BotonFechaHora(
                        icono: Icons.schedule_rounded,
                        texto: _hora == null ? 'Elegir hora' : _hora!.format(context),
                        elegido: _hora != null,
                        onTap: _elegirHora,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              LoadingButton(
                texto: 'Publicar sesión',
                textoCargando: 'Publicando...',
                cargando: _guardando,
                onPressed: _guardar,
                icono: Icons.campaign_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BotonFechaHora extends StatelessWidget {
  final IconData icono;
  final String texto;
  final bool elegido;
  final VoidCallback onTap;

  const _BotonFechaHora({
    required this.icono,
    required this.texto,
    required this.elegido,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RumboCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      borderColor: elegido ? RumboColors.crimsonBright.withValues(alpha: 0.35) : null,
      child: Row(
        children: [
          Icon(icono, size: 17, color: elegido ? RumboColors.crimsonBright : RumboColors.textLow),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: elegido ? RumboColors.textHigh : RumboColors.textLow,
                fontSize: 13.5,
                fontWeight: elegido ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
