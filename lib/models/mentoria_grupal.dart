class MentoriaGrupal {
  final String id;
  final String mentorId;
  final String mentorNombre;
  final String titulo;
  final String descripcion;
  final int cupoMaximo;
  final int inscritos;
  final String meetLink;
  final DateTime fechaHora;
  final bool yaInscrito;

  MentoriaGrupal({
    required this.id,
    required this.mentorId,
    required this.mentorNombre,
    required this.titulo,
    required this.descripcion,
    required this.cupoMaximo,
    required this.inscritos,
    required this.meetLink,
    required this.fechaHora,
    required this.yaInscrito,
  });

  int get cuposDisponibles => (cupoMaximo - inscritos).clamp(0, cupoMaximo);
  bool get lleno => inscritos >= cupoMaximo;

  factory MentoriaGrupal.fromJson(Map<String, dynamic> json) {
    return MentoriaGrupal(
      id: json['id'] as String,
      mentorId: json['mentor_id'] as String,
      mentorNombre: json['mentor_nombre'] as String,
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String,
      cupoMaximo: json['cupo_maximo'] as int,
      inscritos: json['inscritos'] as int,
      meetLink: json['meet_link'] as String,
      fechaHora: DateTime.parse(json['fecha_hora'] as String),
      yaInscrito: json['ya_inscrito'] as bool,
    );
  }
}

class InscritoGrupal {
  final String jovenId;
  final String nombre;
  final String email;
  final DateTime fechaInscripcion;

  InscritoGrupal({required this.jovenId, required this.nombre, required this.email, required this.fechaInscripcion});

  factory InscritoGrupal.fromJson(Map<String, dynamic> json) {
    return InscritoGrupal(
      jovenId: json['joven_id'] as String,
      nombre: json['nombre'] as String,
      email: json['email'] as String,
      fechaInscripcion: DateTime.parse(json['fecha_inscripcion'] as String),
    );
  }
}
