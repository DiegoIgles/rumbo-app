import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/mentoria_grupal.dart';
import '../services/api_client.dart';
import '../services/auth_controller.dart';

class MentoriaGrupalScreen extends StatefulWidget {
  const MentoriaGrupalScreen({super.key});

  @override
  State<MentoriaGrupalScreen> createState() => _MentoriaGrupalScreenState();
}

class _MentoriaGrupalScreenState extends State<MentoriaGrupalScreen> {
  late Future<List<MentoriaGrupal>> _future;
  final Set<String> _uniendose = {};

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<MentoriaGrupal>> _load() => context.read<AuthController>().api.mentoriasGrupales();

  void _reload() => setState(() {
        _future = _load();
      });

  Future<void> _unirse(MentoriaGrupal g) async {
    setState(() => _uniendose.add(g.id));
    try {
      await context.read<AuthController>().api.unirseMentoriaGrupal(g.id);
      _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('¡Te uniste a "${g.titulo}"!')));
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo unir a la mentoría')));
    } finally {
      if (mounted) setState(() => _uniendose.remove(g.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mentoría grupal')),
      body: RefreshIndicator(
        onRefresh: () async {
          _reload();
          await _future;
        },
        child: FutureBuilder<List<MentoriaGrupal>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 60),
                  Center(
                    child: Text(
                      snapshot.error is ApiException ? (snapshot.error as ApiException).message : 'Error al cargar las mentorías grupales',
                    ),
                  ),
                ],
              );
            }
            final grupales = snapshot.data ?? [];
            if (grupales.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 60),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text('Todavía no hay mentorías grupales programadas.', textAlign: TextAlign.center),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: grupales.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _GrupalCard(
                grupal: grupales[i],
                uniendose: _uniendose.contains(grupales[i].id),
                onUnirse: () => _unirse(grupales[i]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GrupalCard extends StatelessWidget {
  final MentoriaGrupal grupal;
  final bool uniendose;
  final VoidCallback onUnirse;

  const _GrupalCard({required this.grupal, required this.uniendose, required this.onUnirse});

  @override
  Widget build(BuildContext context) {
    final g = grupal;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(g.titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 4),
            Text('Con ${g.mentorNombre}', style: const TextStyle(color: Colors.black54, fontSize: 13)),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.schedule, size: 15, color: Colors.black45),
                const SizedBox(width: 6),
                Text(formatearFechaHora(g.fechaHora), style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.people_outline, size: 15, color: g.lleno ? const Color(0xFFDC2626) : Colors.black45),
                const SizedBox(width: 6),
                Text(
                  g.lleno ? 'Cupo lleno (${g.inscritos}/${g.cupoMaximo})' : '${g.cuposDisponibles} cupos disponibles de ${g.cupoMaximo}',
                  style: TextStyle(fontSize: 12.5, color: g.lleno ? const Color(0xFFDC2626) : Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(g.descripcion),
            const SizedBox(height: 12),
            if (g.yaInscrito) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri.parse(g.meetLink), mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.videocam_outlined),
                  label: const Text('Abrir Meet'),
                ),
              ),
            ] else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (g.lleno || uniendose) ? null : onUnirse,
                  child: uniendose
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(g.lleno ? 'Cupo lleno' : 'Unirme'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

const _meses = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

String formatearFechaHora(DateTime d) {
  final local = d.toLocal();
  final hora = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  return '${local.day} ${_meses[local.month - 1]} · $hora:$min';
}
