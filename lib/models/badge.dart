class AppBadge {
  final String id;
  final String tipo;
  final String fechaObtenida;

  AppBadge({required this.id, required this.tipo, required this.fechaObtenida});

  factory AppBadge.fromJson(Map<String, dynamic> json) {
    return AppBadge(
      id: json['id'] as String,
      tipo: json['tipo'] as String,
      fechaObtenida: json['fecha_obtenida'] as String,
    );
  }
}

class BadgeInfo {
  final String titulo;
  final String descripcion;

  const BadgeInfo(this.titulo, this.descripcion);
}

const Map<String, BadgeInfo> badgeCatalogo = {
  'constancia_checkin': BadgeInfo('Constancia', 'Hiciste check-in de bienestar varias veces.'),
  'primer_cv_revisado': BadgeInfo('Primer CV revisado', 'Recibiste tu primera revisión de CV con IA.'),
  'primera_practica_entrevista': BadgeInfo('Primera entrevista', 'Practicaste tu primera simulación de entrevista.'),
};

BadgeInfo infoBadge(String tipo) =>
    badgeCatalogo[tipo] ?? BadgeInfo(tipo, 'Logro desbloqueado en Rumbo.');
