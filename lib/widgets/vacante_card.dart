import 'package:flutter/material.dart';

import '../models/vacante.dart';

class VacanteCard extends StatelessWidget {
  final Vacante vacante;
  final VoidCallback onTap;

  const VacanteCard({super.key, required this.vacante, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vacante.titulo,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  _InfoChip(icon: Icons.public, label: vacante.ciudad != null ? '${vacante.ciudad}, ${vacante.pais}' : vacante.pais),
                  _InfoChip(icon: Icons.schedule, label: labelTipoEmpleo(vacante.tipoEmpleo)),
                  _InfoChip(icon: Icons.laptop_mac, label: labelModalidad(vacante.modalidad)),
                  if (vacante.salario != null) _InfoChip(icon: Icons.attach_money, label: vacante.salario!),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Chip(
                    label: Text(vacante.area, style: const TextStyle(fontSize: 12)),
                    backgroundColor: const Color(0xFFF1F5F9),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, size: 18, color: Colors.black38),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.black54),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
      ],
    );
  }
}
