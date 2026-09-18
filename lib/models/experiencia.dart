class Experiencia {
  final String id;
  final String puesto;
  final String empresa;
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final String? referencia;

  Experiencia({
    required this.id,
    required this.puesto,
    required this.empresa,
    required this.fechaInicio,
    required this.fechaFin,
    required this.referencia,
  });

  bool get esActual => fechaFin == null;

  factory Experiencia.fromJson(Map<String, dynamic> json) {
    return Experiencia(
      id: json['id'] as String,
      puesto: json['puesto'] as String,
      empresa: json['empresa'] as String,
      fechaInicio: DateTime.parse(json['fecha_inicio'] as String),
      fechaFin: json['fecha_fin'] != null ? DateTime.parse(json['fecha_fin'] as String) : null,
      referencia: json['referencia'] as String?,
    );
  }
}
