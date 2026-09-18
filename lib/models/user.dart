class AppUser {
  final String id;
  final String nombre;
  final String email;
  final String role;
  final String fechaRegistro;

  AppUser({
    required this.id,
    required this.nombre,
    required this.email,
    required this.role,
    required this.fechaRegistro,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      fechaRegistro: json['fecha_registro'] as String,
    );
  }
}
