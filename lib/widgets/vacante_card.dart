import 'package:flutter/material.dart';

import '../models/vacante.dart';
import '../theme.dart';
import 'ui_kit.dart';

/// Color estable por área: siempre la misma área se ve del mismo color en toda
/// la app, así se reconoce de un vistazo sin leer la etiqueta.
Color colorDeArea(String area) {
  const paleta = [
    RumboColors.crimsonBright,
    RumboColors.navyBright,
    RumboColors.warning,
    RumboColors.success,
    Color(0xFFB07CD6),
  ];
  return paleta[area.hashCode.abs() % paleta.length];
}

class VacanteCard extends StatelessWidget {
  final Vacante vacante;
  final VoidCallback onTap;

  const VacanteCard({super.key, required this.vacante, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final v = vacante;
    final acento = colorDeArea(v.area);
    final ubicacion = v.ciudad != null && v.ciudad!.isNotEmpty ? '${v.ciudad}, ${v.pais}' : v.pais;

    return RumboCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Franja de color del área: da identidad sin ocupar lugar.
              Container(
                width: 3.5,
                height: 38,
                margin: const EdgeInsets.only(right: 12, top: 2),
                decoration: BoxDecoration(
                  color: acento,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(
                      tag: 'vacante-titulo-${v.id}',
                      flightShuttleBuilder: (_, _, _, _, _) => Material(
                        color: Colors.transparent,
                        child: Text(
                          v.titulo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          v.titulo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    RumboTag(texto: v.area, color: acento),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 6, left: 6),
                child: Icon(Icons.chevron_right_rounded, size: 20, color: RumboColors.textLow),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              MetaRow(icono: Icons.place_outlined, texto: ubicacion),
              MetaRow(icono: Icons.schedule_rounded, texto: labelTipoEmpleo(v.tipoEmpleo)),
              MetaRow(icono: Icons.laptop_mac_rounded, texto: labelModalidad(v.modalidad)),
            ],
          ),
          if (v.salario != null && v.salario!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: RumboColors.success.withValues(alpha: 0.12),
                borderRadius: RumboRadii.pill,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.payments_outlined, size: 13, color: RumboColors.success),
                  const SizedBox(width: 6),
                  Text(
                    v.salario!,
                    style: const TextStyle(
                      color: RumboColors.success,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
