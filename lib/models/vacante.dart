class Vacante {
  final String id;
  final String titulo;
  final String area;
  final String pais;
  final String? descripcion;
  final String? tipoEmpleo;
  final String? modalidad;
  final String? ciudad;
  final String? salario;
  final String fechaPublicacion;
  final bool activa;
  final int totalPostulaciones;

  Vacante({
    required this.id,
    required this.titulo,
    required this.area,
    required this.pais,
    required this.descripcion,
    required this.tipoEmpleo,
    required this.modalidad,
    required this.ciudad,
    required this.salario,
    required this.fechaPublicacion,
    required this.activa,
    required this.totalPostulaciones,
  });

  factory Vacante.fromJson(Map<String, dynamic> json) {
    return Vacante(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      area: json['area'] as String,
      pais: json['pais'] as String,
      descripcion: json['descripcion'] as String?,
      tipoEmpleo: json['tipo_empleo'] as String?,
      modalidad: json['modalidad'] as String?,
      ciudad: json['ciudad'] as String?,
      salario: json['salario'] as String?,
      fechaPublicacion: json['fecha_publicacion'] as String,
      activa: json['activa'] as bool,
      totalPostulaciones: json['total_postulaciones'] as int,
    );
  }
}

const Map<String, String> tiposEmpleoLabels = {
  'pasantia': 'Pasantía',
  'medio_tiempo': 'Medio tiempo',
  'tiempo_completo': 'Tiempo completo',
  'freelance': 'Freelance / por proyecto',
  'temporal': 'Temporal',
};

const Map<String, String> modalidadLabels = {
  'presencial': 'Presencial',
  'remoto': 'Remoto',
  'hibrido': 'Híbrido',
};

String labelTipoEmpleo(String? value) => tiposEmpleoLabels[value] ?? 'No especificado';

String labelModalidad(String? value) => modalidadLabels[value] ?? 'No especificada';
