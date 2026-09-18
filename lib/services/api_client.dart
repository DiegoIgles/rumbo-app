import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/badge.dart';
import '../models/checkin.dart';
import '../models/cv_review.dart';
import '../models/dashboard.dart';
import '../models/experiencia.dart';
import '../models/mentoria.dart';
import '../models/mentoria_grupal.dart';
import '../models/profile.dart';
import '../models/user.dart';
import '../models/vacante.dart';

class ApiException implements Exception {
  final String message;
  final int status;

  ApiException(this.message, this.status);

  @override
  String toString() => message;
}

class LoginResult {
  final String accessToken;
  final String role;

  LoginResult({required this.accessToken, required this.role});
}

/// Cliente HTTP para el backend FastAPI. Espeja lib/api/client.ts del panel web.
class ApiClient {
  /// Provee el token JWT vigente (o null si no hay sesión). Lo inyecta
  /// AuthController para no acoplar este cliente al almacenamiento local.
  final String? Function() tokenProvider;

  ApiClient({required this.tokenProvider});

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('$apiBaseUrl$path').replace(queryParameters: query);
  }

  Map<String, String> _headers() {
    final token = tokenProvider();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<T> _request<T>(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    required T Function(dynamic json) parse,
  }) async {
    http.Response response;
    final uri = _uri(path, query);
    try {
      switch (method) {
        case 'GET':
          response = await http.get(uri, headers: _headers());
          break;
        case 'POST':
          response = await http.post(uri, headers: _headers(), body: body == null ? null : jsonEncode(body));
          break;
        case 'PUT':
          response = await http.put(uri, headers: _headers(), body: body == null ? null : jsonEncode(body));
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: _headers());
          break;
        default:
          throw ArgumentError('Método no soportado: $method');
      }
    } catch (_) {
      throw ApiException('No se pudo conectar con el servidor. Verificá que el backend esté corriendo.', 0);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Error ${response.statusCode}';
      try {
        final body = jsonDecode(response.body);
        final detail = body['detail'];
        if (detail is String) {
          message = detail;
        } else if (detail is List) {
          message = detail.map((d) => d is Map ? d['msg'] ?? d.toString() : d.toString()).join(', ');
        }
      } catch (_) {
        // Respuesta sin cuerpo JSON: se mantiene el mensaje genérico.
      }
      throw ApiException(message, response.statusCode);
    }

    if (response.statusCode == 204 || response.body.isEmpty) {
      return parse(null);
    }
    return parse(jsonDecode(utf8.decode(response.bodyBytes)));
  }

  Future<LoginResult> login(String email, String password) {
    return _request(
      'POST',
      '/auth/login',
      body: {'email': email, 'password': password},
      parse: (json) => LoginResult(accessToken: json['access_token'] as String, role: json['role'] as String),
    );
  }

  Future<AppUser> register({
    required String nombre,
    required String email,
    required String password,
    String role = 'joven',
  }) {
    return _request(
      'POST',
      '/auth/register',
      body: {'nombre': nombre, 'email': email, 'password': password, 'role': role},
      parse: (json) => AppUser.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<AppUser> me() {
    return _request('GET', '/auth/me', parse: (json) => AppUser.fromJson(json as Map<String, dynamic>));
  }

  Future<AppProfile?> getProfile() async {
    try {
      return await _request(
        'GET',
        '/profile',
        parse: (json) => AppProfile.fromJson(json as Map<String, dynamic>),
      );
    } on ApiException catch (e) {
      if (e.status == 404) return null;
      rethrow;
    }
  }

  Future<AppProfile> upsertProfile(AppProfile profile) {
    return _request(
      'POST',
      '/profile',
      body: profile.toJson(),
      parse: (json) => AppProfile.fromJson(json as Map<String, dynamic>),
    );
  }

  // ---------- Experiencia laboral ----------
  Future<List<Experiencia>> listarExperiencia() {
    return _request(
      'GET',
      '/profile/experiencia',
      parse: (json) => (json as List).map((e) => Experiencia.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Future<Experiencia> crearExperiencia({
    required String puesto,
    required String empresa,
    required DateTime fechaInicio,
    DateTime? fechaFin,
    String? referencia,
  }) {
    return _request(
      'POST',
      '/profile/experiencia',
      body: {
        'puesto': puesto,
        'empresa': empresa,
        'fecha_inicio': _dateOnly(fechaInicio),
        'fecha_fin': fechaFin != null ? _dateOnly(fechaFin) : null,
        'referencia': referencia,
      },
      parse: (json) => Experiencia.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Experiencia> editarExperiencia({
    required String id,
    required String puesto,
    required String empresa,
    required DateTime fechaInicio,
    DateTime? fechaFin,
    String? referencia,
  }) {
    return _request(
      'PUT',
      '/profile/experiencia/$id',
      body: {
        'puesto': puesto,
        'empresa': empresa,
        'fecha_inicio': _dateOnly(fechaInicio),
        'fecha_fin': fechaFin != null ? _dateOnly(fechaFin) : null,
        'referencia': referencia,
      },
      parse: (json) => Experiencia.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> eliminarExperiencia(String id) {
    return _request('DELETE', '/profile/experiencia/$id', parse: (_) {});
  }

  String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<List<Vacante>> listarVacantes({String? area, String? pais}) {
    return _request(
      'GET',
      '/vacantes',
      query: {
        if (area != null && area.isNotEmpty) 'area': area,
        if (pais != null && pais.isNotEmpty) 'pais': pais,
      },
      parse: (json) => (json as List).map((v) => Vacante.fromJson(v as Map<String, dynamic>)).toList(),
    );
  }

  Future<List<Vacante>> vacantesRecomendadas() {
    return _request(
      'GET',
      '/vacantes/recomendadas',
      parse: (json) => (json as List).map((v) => Vacante.fromJson(v as Map<String, dynamic>)).toList(),
    );
  }

  Future<void> postular(String vacanteId) {
    return _request('POST', '/vacantes/$vacanteId/postular', parse: (_) {});
  }

  // ---------- Check-in de bienestar ----------
  Future<CheckinResult> crearCheckin(int nivelEmocional) {
    return _request(
      'POST',
      '/checkin',
      body: {'nivel_emocional': nivelEmocional},
      parse: (json) => CheckinResult.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<List<CheckinResult>> historialCheckin() {
    return _request(
      'GET',
      '/checkin/historial',
      parse: (json) => (json as List).map((c) => CheckinResult.fromJson(c as Map<String, dynamic>)).toList(),
    );
  }

  Future<List<RecursoApoyo>> recursosApoyo() {
    return _request(
      'GET',
      '/wellbeing/recursos-apoyo',
      parse: (json) => (json as List).map((r) => RecursoApoyo.fromJson(r as Map<String, dynamic>)).toList(),
    );
  }

  // ---------- Dashboard ----------
  Future<DashboardData> dashboard() {
    return _request('GET', '/dashboard', parse: (json) => DashboardData.fromJson(json as Map<String, dynamic>));
  }

  // ---------- CV / pitch con IA ----------
  Future<CvReview> reviewCv({required String modo, required String texto}) async {
    final uri = _uri('/cv/review');
    final token = tokenProvider();
    http.Response response;
    try {
      response = await http.post(
        uri,
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
        body: {'modo': modo, 'texto': texto},
      );
    } catch (_) {
      throw ApiException('No se pudo conectar con el servidor. Verificá que el backend esté corriendo.', 0);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_extractError(response), response.statusCode);
    }
    return CvReview.fromJson(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
  }

  /// Sube un CV/pitch como archivo (.pdf o .docx) en vez de texto pegado.
  /// [bytes] se usa cuando no hay una ruta en disco (por ejemplo en web);
  /// si está presente tiene prioridad sobre [rutaArchivo].
  Future<CvReview> reviewCvArchivo({
    required String modo,
    required String nombreArchivo,
    String? rutaArchivo,
    List<int>? bytes,
  }) async {
    final uri = _uri('/cv/review');
    final token = tokenProvider();
    http.StreamedResponse streamed;
    try {
      final request = http.MultipartRequest('POST', uri)
        ..fields['modo'] = modo
        ..headers.addAll({if (token != null) 'Authorization': 'Bearer $token'});
      if (bytes != null) {
        request.files.add(http.MultipartFile.fromBytes('archivo', bytes, filename: nombreArchivo));
      } else if (rutaArchivo != null) {
        request.files.add(await http.MultipartFile.fromPath('archivo', rutaArchivo, filename: nombreArchivo));
      } else {
        throw ArgumentError('Se necesita rutaArchivo o bytes');
      }
      streamed = await request.send();
    } catch (_) {
      throw ApiException('No se pudo conectar con el servidor. Verificá que el backend esté corriendo.', 0);
    }
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_extractError(response), response.statusCode);
    }
    return CvReview.fromJson(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
  }

  Future<List<CvReview>> listarCvReviews() {
    return _request(
      'GET',
      '/cv/reviews',
      parse: (json) => (json as List).map((r) => CvReview.fromJson(r as Map<String, dynamic>)).toList(),
    );
  }

  /// Compara la última versión del CV con la anterior (mismo modo). Devuelve
  /// hayComparacion=false si todavía no hay una versión previa contra la cual
  /// comparar.
  Future<ComparacionCv> comparacionCv(String modo) {
    return _request(
      'GET',
      '/cv/comparacion',
      query: {'modo': modo},
      parse: (json) => ComparacionCv.fromJson(json as Map<String, dynamic>),
    );
  }

  // ---------- Práctica de entrevistas ----------
  Future<({String sessionId, String mensajeInicial})> interviewStart({
    required String modo,
    String? sector,
  }) {
    return _request(
      'POST',
      '/interview/start',
      body: {'modo': modo, 'sector': ?sector, 'idioma': 'es'},
      parse: (json) => (sessionId: json['session_id'] as String, mensajeInicial: json['mensaje_inicial'] as String),
    );
  }

  Future<String> interviewMessage({required String sessionId, required String mensaje}) {
    return _request(
      'POST',
      '/interview/message',
      body: {'session_id': sessionId, 'mensaje': mensaje, 'idioma': 'es'},
      parse: (json) => json['respuesta'] as String,
    );
  }

  /// Cierra la práctica y le pide a la IA una evaluación final del desempeño
  /// (misma forma que el feedback de CV: resumen/fortalezas/a_mejorar).
  Future<CvFeedback> interviewFinalizar(String sessionId) {
    return _request(
      'POST',
      '/interview/$sessionId/finalizar',
      parse: (json) => CvFeedback.fromJson(json as Map<String, dynamic>),
    );
  }

  // ---------- Insignias ----------
  Future<List<AppBadge>> badges() {
    return _request(
      'GET',
      '/badges',
      parse: (json) => (json as List).map((b) => AppBadge.fromJson(b as Map<String, dynamic>)).toList(),
    );
  }

  // ---------- Mentoría ----------
  Future<List<MentorProfile>> mentores({String? area}) {
    return _request(
      'GET',
      '/mentoring/mentores',
      query: {if (area != null && area.isNotEmpty) 'area': area},
      parse: (json) => (json as List).map((m) => MentorProfile.fromJson(m as Map<String, dynamic>)).toList(),
    );
  }

  Future<Mentoria> solicitarMentoria({required String mentorId, String? mensajeInicial}) {
    return _request(
      'POST',
      '/mentoring/solicitar',
      body: {'mentor_id': mentorId, 'mensaje_inicial': ?mensajeInicial},
      parse: (json) => Mentoria.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<List<Mentoria>> misMentorias() {
    return _request(
      'GET',
      '/mentoring/mias',
      parse: (json) => (json as List).map((m) => Mentoria.fromJson(m as Map<String, dynamic>)).toList(),
    );
  }

  /// Solo para cuentas con role "mentor": acepta o rechaza una solicitud recibida.
  Future<Mentoria> responderMentoria({required String mentoriaId, required bool aceptar}) {
    return _request(
      'POST',
      '/mentoring/$mentoriaId/responder',
      body: {'estado': aceptar ? 'aceptada' : 'rechazada'},
      parse: (json) => Mentoria.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Solo para cuentas con role "mentor": crea o actualiza el perfil público
  /// que ven los jóvenes al buscar mentores.
  Future<MentorProfile> upsertMentorProfile({
    required String areaExpertise,
    String? bio,
    String? disponibilidad,
  }) {
    return _request(
      'POST',
      '/mentoring/perfil',
      body: {'area_expertise': areaExpertise, 'bio': bio, 'disponibilidad': disponibilidad},
      parse: (json) => MentorProfile.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<List<MentoriaMensaje>> mensajesMentoria(String mentoriaId) {
    return _request(
      'GET',
      '/mentoring/$mentoriaId/mensajes',
      parse: (json) => (json as List).map((m) => MentoriaMensaje.fromJson(m as Map<String, dynamic>)).toList(),
    );
  }

  Future<MentoriaMensaje> enviarMensajeMentoria(String mentoriaId, String texto) {
    return _request(
      'POST',
      '/mentoring/$mentoriaId/mensajes',
      body: {'texto': texto},
      parse: (json) => MentoriaMensaje.fromJson(json as Map<String, dynamic>),
    );
  }

  // ---------- Mentoría grupal ----------
  Future<List<MentoriaGrupal>> mentoriasGrupales() {
    return _request(
      'GET',
      '/mentoring/grupales',
      parse: (json) => (json as List).map((g) => MentoriaGrupal.fromJson(g as Map<String, dynamic>)).toList(),
    );
  }

  Future<List<MentoriaGrupal>> misMentoriasGrupales() {
    return _request(
      'GET',
      '/mentoring/grupales/mias',
      parse: (json) => (json as List).map((g) => MentoriaGrupal.fromJson(g as Map<String, dynamic>)).toList(),
    );
  }

  Future<MentoriaGrupal> crearMentoriaGrupal({
    required String titulo,
    required String descripcion,
    required int cupoMaximo,
    required String meetLink,
    required DateTime fechaHora,
  }) {
    return _request(
      'POST',
      '/mentoring/grupales',
      body: {
        'titulo': titulo,
        'descripcion': descripcion,
        'cupo_maximo': cupoMaximo,
        'meet_link': meetLink,
        'fecha_hora': fechaHora.toIso8601String(),
      },
      parse: (json) => MentoriaGrupal.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<MentoriaGrupal> unirseMentoriaGrupal(String grupalId) {
    return _request(
      'POST',
      '/mentoring/grupales/$grupalId/unirse',
      parse: (json) => MentoriaGrupal.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<List<InscritoGrupal>> inscritosMentoriaGrupal(String grupalId) {
    return _request(
      'GET',
      '/mentoring/grupales/$grupalId/inscritos',
      parse: (json) => (json as List).map((i) => InscritoGrupal.fromJson(i as Map<String, dynamic>)).toList(),
    );
  }

  String _extractError(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      final detail = body['detail'];
      if (detail is String) return detail;
      if (detail is List) {
        return detail.map((d) => d is Map ? d['msg'] ?? d.toString() : d.toString()).join(', ');
      }
    } catch (_) {
      // Respuesta sin cuerpo JSON: se mantiene el mensaje genérico.
    }
    return 'Error ${response.statusCode}';
  }
}
