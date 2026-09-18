import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app_constants.dart';
import '../models/vacante.dart';
import '../services/api_client.dart';
import '../services/auth_controller.dart';
import '../theme.dart';
import '../widgets/ui_kit.dart';
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
    return context.read<AuthController>().api.listarVacantes(area: _area, pais: _pais);
  }

  void _reload() => setState(() {
        _future = _load();
      });

  void _setArea(String? a) {
    HapticFeedback.selectionClick();
    _area = a;
    _reload();
  }

  void _setPais(String? p) {
    HapticFeedback.selectionClick();
    _pais = p;
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: FadeSlideIn(
                index: 0,
                child: BrandHeader(
                  icono: Icons.work_outline,
                  titulo: 'Vacantes',
                  subtitulo: 'Oportunidades abiertas para arrancar tu carrera.',
                ),
              ),
            ),
            const SizedBox(height: 16),
            _FiltroFila(
              etiquetaTodos: 'Todas las áreas',
              opciones: areas,
              seleccion: _area,
              onSeleccionar: _setArea,
            ),
            const SizedBox(height: 8),
            _FiltroFila(
              etiquetaTodos: 'Todos los países',
              opciones: paises,
              seleccion: _pais,
              onSeleccionar: _setPais,
            ),
            const SizedBox(height: 6),
            Expanded(
              child: RumboRefresh(
                onRefresh: () async {
                  _reload();
                  await _future.catchError((_) => <Vacante>[]);
                },
                child: FutureBuilder<List<Vacante>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SkeletonList(cantidad: 4, padding: EdgeInsets.fromLTRB(16, 10, 16, 110));
                    }
                    if (snapshot.hasError) {
                      final msg = snapshot.error is ApiException
                          ? (snapshot.error as ApiException).message
                          : 'No pudimos cargar las vacantes';
                      return ScrollableStatusView(
                        view: StatusView(
                          icono: Icons.cloud_off_rounded,
                          titulo: 'No se pudo conectar',
                          detalle: msg,
                          textoAccion: 'Reintentar',
                          onAccion: _reload,
                          esError: true,
                        ),
                      );
                    }
                    final vacantes = snapshot.data ?? [];
                    if (vacantes.isEmpty) {
                      return const ScrollableStatusView(
                        view: StatusView(
                          icono: Icons.search_off_rounded,
                          titulo: 'Sin resultados',
                          detalle: 'No hay vacantes con estos filtros. Probá quitando alguno.',
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
                      itemCount: vacantes.length + 1,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        if (i == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              vacantes.length == 1
                                  ? '1 vacante encontrada'
                                  : '${vacantes.length} vacantes encontradas',
                              style: const TextStyle(color: RumboColors.textLow, fontSize: 12.5),
                            ),
                          );
                        }
                        final v = vacantes[i - 1];
                        return FadeSlideIn(
                          key: ValueKey(v.id),
                          index: i - 1,
                          child: VacanteCard(
                            vacante: v,
                            onTap: () => Navigator.of(context).push(
                              RumboPageRoute(builder: (_) => VacanteDetailScreen(vacante: v)),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fila horizontal de chips. Reemplaza a los dos DropdownButtonFormField que
/// había antes: se filtra con un toque y se ve el estado sin abrir un menú.
class _FiltroFila extends StatelessWidget {
  final String etiquetaTodos;
  final List<String> opciones;
  final String? seleccion;
  final ValueChanged<String?> onSeleccionar;

  const _FiltroFila({
    required this.etiquetaTodos,
    required this.opciones,
    required this.seleccion,
    required this.onSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _Chip(
            texto: etiquetaTodos,
            activo: seleccion == null,
            onTap: () => onSeleccionar(null),
          ),
          for (final o in opciones)
            _Chip(
              texto: o,
              activo: seleccion == o,
              onTap: () => onSeleccionar(seleccion == o ? null : o),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String texto;
  final bool activo;
  final VoidCallback onTap;

  const _Chip({required this.texto, required this.activo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: RumboMotion.fast,
          curve: RumboMotion.emphasized,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
          decoration: BoxDecoration(
            color: activo ? RumboColors.crimson : RumboColors.surface,
            borderRadius: RumboRadii.pill,
            border: Border.all(color: activo ? RumboColors.crimson : RumboColors.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                texto,
                style: TextStyle(
                  color: activo ? Colors.white : RumboColors.textMid,
                  fontSize: 12.5,
                  fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
