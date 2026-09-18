import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/vacante.dart';
import '../services/api_client.dart';
import '../services/auth_controller.dart';

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
    setState(() {
      _postulando = true;
      _mensaje = null;
    });
    try {
      await context.read<AuthController>().api.postular(widget.vacante.id);
      setState(() {
        _postulado = true;
        _mensaje = '¡Listo! Tu postulación fue enviada.';
        _esError = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _mensaje = e.message;
        _esError = true;
        if (e.status == 400 && e.message.toLowerCase().contains('ya te postulaste')) {
          _postulado = true;
        }
      });
    } catch (_) {
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
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de vacante')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(v.titulo, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _DetailRow(icon: Icons.public, text: v.ciudad != null ? '${v.ciudad}, ${v.pais}' : v.pais),
                  _DetailRow(icon: Icons.schedule, text: labelTipoEmpleo(v.tipoEmpleo)),
                  _DetailRow(icon: Icons.laptop_mac, text: labelModalidad(v.modalidad)),
                  if (v.salario != null) _DetailRow(icon: Icons.attach_money, text: v.salario!),
                ],
              ),
              const SizedBox(height: 16),
              Chip(
                label: Text(v.area),
                backgroundColor: const Color(0xFFF1F5F9),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(height: 24),
              if (v.descripcion != null && v.descripcion!.isNotEmpty) ...[
                Text('Descripción', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(v.descripcion!, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 24),
              ],
              if (_mensaje != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _esError ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _esError ? Icons.error_outline : Icons.check_circle_outline,
                        size: 18,
                        color: _esError ? const Color(0xFFDC2626) : const Color(0xFF059669),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _mensaje!,
                          style: TextStyle(color: _esError ? const Color(0xFFDC2626) : const Color(0xFF059669)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_postulando || _postulado) ? null : _postular,
                  icon: _postulando
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(_postulado ? Icons.check : Icons.send),
                  label: Text(_postulado ? 'Ya te postulaste' : (_postulando ? 'Enviando...' : 'Postularme')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.black54),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.black87)),
      ],
    );
  }
}
