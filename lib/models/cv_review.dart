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
