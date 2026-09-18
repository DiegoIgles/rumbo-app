import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/vacante.dart';
import '../services/api_client.dart';
import '../services/auth_controller.dart';
import '../theme.dart';
import '../utils/formato.dart';
import '../widgets/ui_kit.dart';
import '../widgets/vacante_card.dart';

class VacanteDetailScreen extends StatefulWidget {
  final Vacante vacante;

  const VacanteDetailScreen({super.key, required this.vacante});

  @override
  State<VacanteDetailScreen> createState() => _VacanteDetailScreenState();
}

class _VacanteDetailScreenState extends State<VacanteDetailScreen> {
  bool _postulando = false;
  bool _postulado = false;
  String? _mensaje;
  bool _esError = false;

  Future<void> _postular() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _postulando = true;
      _mensaje = null;
    });
    try {
      await context.read<AuthController>().api.postular(widget.vacante.id);
      if (!mounted) return;
      setState(() {
        _postulado = true;
        _mensaje = '¡Listo! Tu postulación fue enviada.';
        _esError = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _mensaje = e.message;
        _esError = true;
        // "Ya te postulaste" es un 400, pero para el usuario el resultado es el
        // mismo que si acabara de postularse: el botón queda deshabilitado.
        if (e.status == 400 && e.message.toLowerCase().contains('ya te postulaste')) {
          _postulado = true;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _mensaje = 'No se pudo enviar la postulación';
        _esError = true;
      });
    } finally {
      if (mounted) setState(() => _postulando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vacante;
    final acento = colorDeArea(v.area);
    final ubicacion = v.ciudad != null && v.ciudad!.isNotEmpty ? '${v.ciudad}, ${v.pais}' : v.pais;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de vacante')),
      bottomNavigationBar: _BarraPostulacion(
        postulando: _postulando,
        postulado: _postulado,
        onPostular: _postular,
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            FadeSlideIn(
              index: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RumboTag(texto: v.area, color: acento),
                  const SizedBox(height: 14),
                  Hero(
                    tag: 'vacante-titulo-${v.id}',
                    flightShuttleBuilder: (_, _, _, _, _) => Material(
                      color: Colors.transparent,
                      child: Text(v.titulo, style: Theme.of(context).textTheme.headlineSmall),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: Text(v.titulo, style: Theme.of(context).textTheme.headlineSmall),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            FadeSlideIn(
              index: 1,
              child: RumboCard(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                child: Column(
                  children: [
                    _FilaDato(icono: Icons.place_outlined, etiqueta: 'Ubicación', valor: ubicacion),
                    const Divider(),
                    _FilaDato(
                      icono: Icons.schedule_rounded,
                      etiqueta: 'Tipo de empleo',
                      valor: labelTipoEmpleo(v.tipoEmpleo),
                    ),
                    const Divider(),
                    _FilaDato(
                      icono: Icons.laptop_mac_rounded,
                      etiqueta: 'Modalidad',
                      valor: labelModalidad(v.modalidad),
                    ),
                    if (v.salario != null && v.salario!.isNotEmpty) ...[
                      const Divider(),
                      _FilaDato(
                        icono: Icons.payments_outlined,
                        etiqueta: 'Remuneración',
                        valor: v.salario!,
                        colorValor: RumboColors.success,
                      ),
                    ],
                    const Divider(),
                    _FilaDato(
                      icono: Icons.event_outlined,
                      etiqueta: 'Publicada',
                      valor: fechaCortaIso(v.fechaPublicacion),
                    ),
                  ],
                ),
              ),
            ),
            if (v.descripcion != null && v.descripcion!.isNotEmpty) ...[
              const SizedBox(height: 26),
              const FadeSlideIn(index: 2, child: SectionTitle('Descripción')),
              const SizedBox(height: 12),
              FadeSlideIn(
                index: 3,
                child: Text(
                  v.descripcion!,
                  style: const TextStyle(color: RumboColors.textMid, fontSize: 14.5, height: 1.6),
                ),
              ),
            ],
            if (v.totalPostulaciones > 0) ...[
              const SizedBox(height: 22),
              FadeSlideIn(
                index: 4,
                child: Row(
                  children: [
                    const Icon(Icons.groups_outlined, size: 15, color: RumboColors.textLow),
                    const SizedBox(width: 7),
                    Text(
                      v.totalPostulaciones == 1
                          ? '1 persona ya se postuló'
                          : '${v.totalPostulaciones} personas ya se postularon',
                      style: const TextStyle(color: RumboColors.textLow, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
            if (_mensaje != null) ...[
              const SizedBox(height: 22),
              InfoBanner(
                mensaje: _mensaje!,
                tono: _esError && !_postulado ? BannerTono.error : BannerTono.exito,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilaDato extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;
  final Color? colorValor;

  const _FilaDato({
    required this.icono,
    required this.etiqueta,
    required this.valor,
    this.colorValor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Icon(icono, size: 17, color: RumboColors.textLow),
          const SizedBox(width: 13),
          Text(etiqueta, style: const TextStyle(color: RumboColors.textLow, fontSize: 13.5)),
          const Spacer(),
          Flexible(
            child: Text(
              valor,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: colorValor ?? RumboColors.textHigh,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra fija abajo con la acción principal. Estar siempre visible evita que
/// haya que scrollear hasta el final para postularse.
class _BarraPostulacion extends StatelessWidget {
  final bool postulando;
  final bool postulado;
  final VoidCallback onPostular;

  const _BarraPostulacion({
    required this.postulando,
    required this.postulado,
    required this.onPostular,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: RumboColors.ink,
        border: Border(top: BorderSide(color: RumboColors.outlineSoft)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: postulado
              ? Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: RumboColors.successSoft,
                    borderRadius: RumboRadii.field,
                    border: Border.all(color: RumboColors.success.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, color: RumboColors.success, size: 19),
                      SizedBox(width: 9),
                      Text(
                        'Ya te postulaste',
                        style: TextStyle(
                          color: RumboColors.success,
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                    ],
                  ),
                )
              : LoadingButton(
                  texto: 'Postularme',
                  textoCargando: 'Enviando...',
                  cargando: postulando,
                  onPressed: onPostular,
                  icono: Icons.send_rounded,
                ),
        ),
      ),
    );
  }
}
