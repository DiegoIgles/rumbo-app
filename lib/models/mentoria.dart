class MentorProfile {
  final String userId;
  final String nombre;
  final String areaExpertise;
  final String? bio;
  final String? disponibilidad;

  MentorProfile({
    required this.userId,
    required this.nombre,
    required this.areaExpertise,
    required this.bio,
    required this.disponibilidad,
  });

  factory MentorProfile.fromJson(Map<String, dynamic> json) {
    return MentorProfile(
      userId: json['user_id'] as String,
      nombre: json['nombre'] as String,
      areaExpertise: json['area_expertise'] as String,
      bio: json['bio'] as String?,
      disponibilidad: json['disponibilidad'] as String?,
    );
  }
}

class Mentoria {
  final String id;
  final String mentorId;
  final String mentorNombre;
  final String jovenId;
  final String jovenNombre;
  final String estado; // "pendiente" | "aceptada" | "rechazada"
  final String fechaSolicitud;

  Mentoria({
    required this.id,
    required this.mentorId,
    required this.mentorNombre,
    required this.jovenId,
    required this.jovenNombre,
    required this.estado,
    required this.fechaSolicitud,
  });

  factory Mentoria.fromJson(Map<String, dynamic> json) {
    return Mentoria(
      id: json['id'] as String,
      mentorId: json['mentor_id'] as String,
      mentorNombre: json['mentor_nombre'] as String,
      jovenId: json['joven_id'] as String,
      jovenNombre: json['joven_nombre'] as String,
      estado: json['estado'] as String,
      fechaSolicitud: json['fecha_solicitud'] as String,
    );
  }
}

class MentoriaMensaje {
  final String id;
  final String mentoriaId;
  final String remitenteId;
  final String texto;
  final String fecha;

  MentoriaMensaje({
    required this.id,
    required this.mentoriaId,
    required this.remitenteId,
    required this.texto,
    required this.fecha,
  });

  factory MentoriaMensaje.fromJson(Map<String, dynamic> json) {
    return MentoriaMensaje(
      id: json['id'] as String,
      mentoriaId: json['mentoria_id'] as String,
      remitenteId: json['remitente_id'] as String,
      texto: json['texto'] as String,
      fecha: json['fecha'] as String,
    );
  }
}
