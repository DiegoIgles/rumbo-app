class AppProfile {
  final int? edad;
  final String? sectorInteres;
  final String? nivelExperiencia;
  final String rutaPreferida;

  AppProfile({
    required this.edad,
    required this.sectorInteres,
    required this.nivelExperiencia,
    required this.rutaPreferida,
  });

  factory AppProfile.fromJson(Map<String, dynamic> json) {
    return AppProfile(
      edad: json['edad'] as int?,
      sectorInteres: json['sector_interes'] as String?,
      nivelExperiencia: json['nivel_experiencia'] as String?,
      rutaPreferida: json['ruta_preferida'] as String? ?? 'ambas',
    );
  }

  Map<String, dynamic> toJson() => {
        'edad': edad,
        'sector_interes': sectorInteres,
        'nivel_experiencia': nivelExperiencia,
        'ruta_preferida': rutaPreferida,
      };
}
