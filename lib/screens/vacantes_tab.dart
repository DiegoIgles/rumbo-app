import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_constants.dart';
import '../models/vacante.dart';
import '../services/api_client.dart';
import '../services/auth_controller.dart';
import '../widgets/vacante_card.dart';
import 'vacante_detail_screen.dart';

class VacantesTab extends StatefulWidget {
  const VacantesTab({super.key});

  @override
  State<VacantesTab> createState() => _VacantesTabState();
}

class _VacantesTabState extends State<VacantesTab> {
  String? _area;
  String? _pais;
  late Future<List<Vacante>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Vacante>> _load() {
    final api = context.read<AuthController>().api;
    return api.listarVacantes(area: _area, pais: _pais);
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vacantes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    key: ValueKey('area-$_area'),
                    initialValue: _area,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Área', isDense: true),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todas')),
                      ...areas.map((a) => DropdownMenuItem(value: a, child: Text(a, overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: (v) {
                      _area = v;
                      _reload();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    key: ValueKey('pais-$_pais'),
                    initialValue: _pais,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'País', isDense: true),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todos')),
                      ...paises.map((p) => DropdownMenuItem(value: p, child: Text(p))),
                    ],
                    onChanged: (v) {
                      _pais = v;
                      _reload();
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _reload();
                await _future;
              },
              child: FutureBuilder<List<Vacante>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    final message = snapshot.error is ApiException
                        ? (snapshot.error as ApiException).message
                        : 'Error al cargar las vacantes';
                    return _ErrorState(message: message, onRetry: _reload);
                  }
                  final vacantes = snapshot.data ?? [];
                  if (vacantes.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 80),
                        Center(child: Text('No hay vacantes con esos filtros.')),
                      ],
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: vacantes.length,
                    itemBuilder: (context, i) {
                      final v = vacantes[i];
                      return VacanteCard(
                        vacante: v,
                        onTap: () => Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => VacanteDetailScreen(vacante: v))),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 32),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
