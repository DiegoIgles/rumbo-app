class CheckinResult {
  final String id;
  final String fecha;
  final int nivelEmocional;
  final String cargaRecomendada;
  final String mensaje;
  final bool mostrarDerivacionApoyo;

  CheckinResult({
    required this.id,
    required this.fecha,
    required this.nivelEmocional,
    required this.cargaRecomendada,
    required this.mensaje,
    required this.mostrarDerivacionApoyo,
  });

  factory CheckinResult.fromJson(Map<String, dynamic> json) {
    return CheckinResult(
      id: json['id'] as String,
      fecha: json['fecha'] as String,
      nivelEmocional: json['nivel_emocional'] as int,
      cargaRecomendada: json['carga_recomendada'] as String? ?? '',
      mensaje: json['mensaje'] as String? ?? '',
      mostrarDerivacionApoyo: json['mostrar_derivacion_apoyo'] as bool? ?? false,
    );
  }
}

class RecursoApoyo {
  final String nombre;
  final String descripcion;
  final String contacto;

  RecursoApoyo({required this.nombre, required this.descripcion, required this.contacto});

  factory RecursoApoyo.fromJson(Map<String, dynamic> json) {
    return RecursoApoyo(
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String,
      contacto: json['contacto'] as String,
    );
  }
}
