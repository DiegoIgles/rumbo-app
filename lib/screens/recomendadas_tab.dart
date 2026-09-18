import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/vacante.dart';
import '../services/api_client.dart';
import '../services/auth_controller.dart';
import '../theme.dart';
import '../widgets/ui_kit.dart';
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
      body: SafeArea(
        bottom: false,
        child: RumboRefresh(
          onRefresh: () async {
            _reload();
            await _future.catchError((_) => <Vacante>[]);
          },
          child: FutureBuilder<List<Vacante>>(
            future: _future,
            builder: (context, snapshot) {
              final cabecera = Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                child: FadeSlideIn(
                  index: 0,
                  child: BrandHeader(
                    icono: Icons.auto_awesome,
                    titulo: 'Para vos',
                    subtitulo: 'Vacantes elegidas según el área que cargaste en tu perfil.',
                  ),
                ),
              );

              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    cabecera,
                    const SkeletonList(cantidad: 3, padding: EdgeInsets.fromLTRB(16, 0, 16, 110)),
                  ],
                );
              }

              if (snapshot.hasError) {
                final error = snapshot.error;
                // El backend responde 400 cuando el perfil todavía no tiene
                // área cargada: eso no es una falla, es un paso pendiente del
                // usuario, y por eso se muestra distinto de un error de red.
                final perfilIncompleto = error is ApiException && error.status == 400;
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    cabecera,
                    StatusView(
                      icono: perfilIncompleto ? Icons.person_search_outlined : Icons.cloud_off_rounded,
                      titulo: perfilIncompleto ? 'Falta completar tu perfil' : 'No se pudo conectar',
                      detalle: perfilIncompleto
                          ? 'Elegí tu sector de interés y te mostramos las vacantes que mejor encajan.'
                          : (error is ApiException ? error.message : 'Intentalo de nuevo en un momento.'),
                      textoAccion: perfilIncompleto ? 'Ir a mi perfil' : 'Reintentar',
                      onAccion: perfilIncompleto ? widget.onIrAPerfil : _reload,
                      esError: !perfilIncompleto,
                    ),
                  ],
                );
              }

              final vacantes = snapshot.data ?? [];
              if (vacantes.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    cabecera,
                    const StatusView(
                      icono: Icons.explore_outlined,
                      titulo: 'Todavía nada por acá',
                      detalle: 'Aún no hay vacantes publicadas en tu área. Volvé a mirar en unos días.',
                    ),
                  ],
                );
              }

              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 110),
                itemCount: vacantes.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  if (i == 0) return cabecera;
                  final v = vacantes[i - 1];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FadeSlideIn(
                      key: ValueKey(v.id),
                      index: i - 1,
                      child: VacanteCard(
                        vacante: v,
                        onTap: () => Navigator.of(context).push(
                          RumboPageRoute(builder: (_) => VacanteDetailScreen(vacante: v)),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
