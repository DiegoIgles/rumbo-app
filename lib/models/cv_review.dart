class CvFeedback {
  final String resumen;
  final List<String> fortalezas;
  final List<String> aMejorar;
  final String? notaIa;

  CvFeedback({required this.resumen, required this.fortalezas, required this.aMejorar, required this.notaIa});

  factory CvFeedback.fromJson(Map<String, dynamic> json) {
    return CvFeedback(
      resumen: json['resumen'] as String? ?? '',
      fortalezas: (json['fortalezas'] as List? ?? []).map((e) => e.toString()).toList(),
      aMejorar: (json['a_mejorar'] as List? ?? []).map((e) => e.toString()).toList(),
      notaIa: json['nota_ia'] as String?,
    );
  }
}

class CvReview {
  final String id;
  final String modo;
  final String fecha;
  final CvFeedback feedback;

  CvReview({required this.id, required this.modo, required this.fecha, required this.feedback});

  factory CvReview.fromJson(Map<String, dynamic> json) {
    return CvReview(
      id: json['id'] as String,
      modo: json['modo'] as String,
      fecha: json['fecha'] as String,
      feedback: CvFeedback.fromJson(json['feedback_json'] as Map<String, dynamic>),
    );
  }
}

/// Comparacion entre la version mas reciente del CV y la anterior (mismo modo).
/// [hayComparacion] es false cuando el usuario todavia no tiene una version
/// anterior contra la que comparar; en ese caso solo viene [mensaje].
class ComparacionCv {
  final bool hayComparacion;
  final String? mensaje;
  final String? fechaAnterior;
  final String? fechaActual;
  final String? resumen;
  final List<String> mejoras;
  final List<String> pendientes;
  final List<String> nuevasSugerencias;
  final String? notaIa;

  ComparacionCv({
    required this.hayComparacion,
    this.mensaje,
    this.fechaAnterior,
    this.fechaActual,
    this.resumen,
    this.mejoras = const [],
    this.pendientes = const [],
    this.nuevasSugerencias = const [],
    this.notaIa,
  });

  factory ComparacionCv.fromJson(Map<String, dynamic> json) {
    List<String> lista(String clave) =>
        (json[clave] as List? ?? []).map((e) => e.toString()).toList();
    return ComparacionCv(
      hayComparacion: json['hay_comparacion'] as bool? ?? false,
      mensaje: json['mensaje'] as String?,
      fechaAnterior: json['fecha_anterior'] as String?,
      fechaActual: json['fecha_actual'] as String?,
      resumen: json['resumen'] as String?,
      mejoras: lista('mejoras'),
      pendientes: lista('pendientes'),
      nuevasSugerencias: lista('nuevas_sugerencias'),
      notaIa: json['nota_ia'] as String?,
    );
  }
}
