import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/vacante.dart';
import '../services/api_client.dart';
import '../services/auth_controller.dart';
import '../widgets/vacante_card.dart';
import 'vacante_detail_screen.dart';

class RecomendadasTab extends StatefulWidget {
  final VoidCallback onIrAPerfil;

  const RecomendadasTab({super.key, required this.onIrAPerfil});

  @override
  State<RecomendadasTab> createState() => _RecomendadasTabState();
}

class _RecomendadasTabState extends State<RecomendadasTab> {
  late Future<List<Vacante>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Vacante>> _load() => context.read<AuthController>().api.vacantesRecomendadas();

  void _reload() => setState(() {
        _future = _load();
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recomendadas para vos')),
      body: RefreshIndicator(
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
              final isPerfilIncompleto = snapshot.error is ApiException && (snapshot.error as ApiException).status == 400;
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        Icon(
                          isPerfilIncompleto ? Icons.person_outline : Icons.error_outline,
                          size: 32,
                          color: isPerfilIncompleto ? Colors.black45 : const Color(0xFFDC2626),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isPerfilIncompleto
                              ? 'Completá tu perfil para recibir recomendaciones de vacantes según tu área.'
                              : (snapshot.error as ApiException).message,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        if (isPerfilIncompleto)
                          ElevatedButton(onPressed: widget.onIrAPerfil, child: const Text('Ir a mi perfil'))
                        else
                          OutlinedButton(onPressed: _reload, child: const Text('Reintentar')),
                      ],
                    ),
                  ),
                ],
              );
            }
            final vacantes = snapshot.data ?? [];
            if (vacantes.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 80),
                  Center(child: Text('Todavía no hay vacantes recomendadas para tu área.')),
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
                  onTap: () =>
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => VacanteDetailScreen(vacante: v))),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
