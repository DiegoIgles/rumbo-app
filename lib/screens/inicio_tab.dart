import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/checkin.dart';
import '../models/dashboard.dart';
import '../services/api_client.dart';
import '../services/auth_controller.dart';
import '../theme.dart';

class InicioTab extends StatefulWidget {
  const InicioTab({super.key});

  @override
  State<InicioTab> createState() => _InicioTabState();
}

class _InicioTabState extends State<InicioTab> {
  late Future<DashboardData> _future;
  int? _nivelSeleccionado;
  bool _enviandoCheckin = false;
  CheckinResult? _ultimoResultado;
  List<RecursoApoyo>? _recursosApoyo;
  String? _checkinError;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<DashboardData> _load() => context.read<AuthController>().api.dashboard();

  void _reload() => setState(() {
        _future = _load();
      });

  Future<void> _enviarCheckin(int nivel) async {
    setState(() {
      _nivelSeleccionado = nivel;
      _enviandoCheckin = true;
      _checkinError = null;
      _ultimoResultado = null;
      _recursosApoyo = null;
    });
    try {
      final api = context.read<AuthController>().api;
      final resultado = await api.crearCheckin(nivel);
      setState(() => _ultimoResultado = resultado);
      if (resultado.mostrarDerivacionApoyo) {
        final recursos = await api.recursosApoyo();
        setState(() => _recursosApoyo = recursos);
      }
      _reload();
    } on ApiException catch (e) {
      setState(() => _checkinError = e.message);
    } catch (e) {
      setState(() => _checkinError = 'No se pudo registrar tu check-in ($e)');
    } finally {
      if (mounted) setState(() => _enviandoCheckin = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombre = context.watch<AuthController>().user?.nombre.split(' ').first ?? '';
    return Scaffold(
      appBar: AppBar(title: Text('Hola, $nombre')),
      body: RefreshIndicator(
        onRefresh: () async {
          _reload();
          await _future;
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CheckinCard(
                seleccionado: _nivelSeleccionado,
                enviando: _enviandoCheckin,
                resultado: _ultimoResultado,
                error: _checkinError,
                onSeleccionar: _enviarCheckin,
              ),
              if (_recursosApoyo != null) ...[
                const SizedBox(height: 16),
                _RecursosApoyoCard(recursos: _recursosApoyo!),
              ],
              const SizedBox(height: 20),
              FutureBuilder<DashboardData>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        snapshot.error is ApiException ? (snapshot.error as ApiException).message : 'Error al cargar tu resumen',
                      ),
                    );
                  }
                  final data = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tu progreso', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              icon: Icons.favorite_outline,
                              label: 'Check-ins',
                              value: '${data.totalCheckins}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatTile(
                              icon: Icons.description_outlined,
                              label: 'CVs revisados',
                              value: '${data.totalCvReviews}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              icon: Icons.forum_outlined,
                              label: 'Entrevistas',
                              value: '${data.totalInterviewSessions}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatTile(
                              icon: Icons.emoji_events_outlined,
                              label: 'Insignias',
                              value: '${data.badges.length}',
                            ),
                          ),
                        ],
                      ),
                      if (data.ultimosCheckins.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text('Últimos check-ins', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        ...data.ultimosCheckins.map(
                          (c) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Text(_emoji(c.nivelEmocional), style: const TextStyle(fontSize: 22)),
                            title: Text(_fecha(c.fecha)),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _emoji(int nivel) => const ['😞', '🙁', '😐', '🙂', '😄'][(nivel - 1).clamp(0, 4)];

String _fecha(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _CheckinCard extends StatelessWidget {
  final int? seleccionado;
  final bool enviando;
  final CheckinResult? resultado;
  final String? error;
  final ValueChanged<int> onSeleccionar;

  const _CheckinCard({
    required this.seleccionado,
    required this.enviando,
    required this.resultado,
    required this.error,
    required this.onSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Cómo te sentís hoy?', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Tu check-in diario ajusta cuánto te proponemos avanzar hoy.', style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (i) {
                final nivel = i + 1;
                final selected = seleccionado == nivel;
                return InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: enviando ? null : () => onSeleccionar(nivel),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: selected ? rumboPrimary.withValues(alpha: 0.15) : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(_emoji(nivel), style: const TextStyle(fontSize: 26)),
                  ),
                );
              }),
            ),
            if (enviando) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
            if (error != null) ...[
              const SizedBox(height: 16),
              Text(error!, style: const TextStyle(color: Color(0xFFDC2626))),
            ],
            if (!enviando && resultado != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(10)),
                child: Text(resultado!.mensaje, style: const TextStyle(color: Color(0xFF059669))),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecursosApoyoCard extends StatelessWidget {
  final List<RecursoApoyo> recursos;

  const _RecursosApoyoCard({required this.recursos});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFFBEB),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.support_agent, color: Color(0xFFB45309)),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Notamos que veniste sintiéndote mal', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Estos recursos pueden ayudarte:'),
            const SizedBox(height: 8),
            ...recursos.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(r.descripcion, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                    Text(r.contacto, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: rumboPrimary),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12.5)),
          ],
        ),
      ),
    );
  }
}
