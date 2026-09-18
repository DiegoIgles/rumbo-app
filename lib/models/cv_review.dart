import 'dart:convert';

/// A veces la IA no devuelve el JSON estructurado que espera el backend y
/// este, como respaldo, guarda el texto crudo (que resulta ser JSON) en un
/// campo de texto simple. Esto decodifica ese caso para no mostrarle al
/// usuario las llaves y comillas crudas.
String textoLegible(dynamic valor) {
  if (valor == null) return '';
  if (valor is! String) return _aTexto(valor);
  final texto = valor.trim();
  final pareceJson =
      (texto.startsWith('{') && texto.endsWith('}')) || (texto.startsWith('[') && texto.endsWith(']'));
  if (!pareceJson) return valor;
  try {
    return _aTexto(jsonDecode(texto));
  } catch (_) {
    return valor;
  }
}

String _aTexto(dynamic valor) {
  if (valor == null) return '';
  if (valor is String) return textoLegible(valor);
  if (valor is List) {
    return valor.map(_aTexto).where((s) => s.isNotEmpty).join('. ');
  }
  if (valor is Map) {
    for (final clave in ['resumen', 'mensaje', 'texto', 'detalle', 'descripcion']) {
      final v = valor[clave];
      if (v is String && v.trim().isNotEmpty) return textoLegible(v);
    }
    return valor.values.map(_aTexto).where((s) => s.isNotEmpty).join('. ');
  }
  return valor.toString();
}

/// Igual que [textoLegible] pero para una lista completa (fortalezas,
/// mejoras, etc.), filtrando entradas vacías.
List<String> listaDeTextos(dynamic valor) {
  if (valor is! List) return const [];
  return valor.map(_aTexto).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
}

class CvFeedback {
  final String resumen;
  final List<String> fortalezas;
  final List<String> aMejorar;
  final String? notaIa;

  CvFeedback({required this.resumen, required this.fortalezas, required this.aMejorar, required this.notaIa});

  factory CvFeedback.fromJson(Map<String, dynamic> json) {
    return CvFeedback(
      resumen: textoLegible(json['resumen']),
      fortalezas: listaDeTextos(json['fortalezas']),
      aMejorar: listaDeTextos(json['a_mejorar']),
      notaIa: json['nota_ia'] == null ? null : textoLegible(json['nota_ia']),
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
    return ComparacionCv(
      hayComparacion: json['hay_comparacion'] as bool? ?? false,
      mensaje: json['mensaje'] == null ? null : textoLegible(json['mensaje']),
      fechaAnterior: json['fecha_anterior'] as String?,
      fechaActual: json['fecha_actual'] as String?,
      resumen: json['resumen'] == null ? null : textoLegible(json['resumen']),
      mejoras: listaDeTextos(json['mejoras']),
      pendientes: listaDeTextos(json['pendientes']),
      nuevasSugerencias: listaDeTextos(json['nuevas_sugerencias']),
      notaIa: json['nota_ia'] == null ? null : textoLegible(json['nota_ia']),
    );
  }
}
