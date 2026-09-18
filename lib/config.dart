import 'package:flutter/foundation.dart' show ChangeNotifier, kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

/// Dónde vive el backend (FastAPI).
///
/// Antes esto era una constante con la IP de la laptop del equipo, lo que
/// obligaba a recompilar para cambiar de red y dejaba inservible cualquier APK
/// distribuido. Ahora el valor se guarda en el dispositivo y se puede editar
/// desde la pantalla de login, así el mismo APK sirve en cualquier red.
class ApiConfig extends ChangeNotifier {
  ApiConfig._();

  static final ApiConfig instance = ApiConfig._();

  static const String _prefsKey = 'rumbo_api_base_url';

  /// Valor de fábrica: IP de la laptop en la red Wi-Fi actual.
  static const String valorPorDefecto = 'http://10.253.6.7:8001';

  /// Para probar en celular físico por USB con `adb reverse tcp:8000
  /// tcp:8000`, el teléfono ve el backend de la laptop como localhost.
  static const String sugerenciaUsb = 'http://127.0.0.1:8000';

  /// En emulador de Android el host de la laptop no es localhost sino 10.0.2.2.
  static const String sugerenciaEmulador = 'http://10.0.2.2:8000';
  static const String sugerenciaLocal = 'http://localhost:8000';
  static const String sugerenciaWifiLaptop = 'http://10.253.12.184:8000';
  static const String sugerenciaPuertoAlterno = 'http://10.253.12.184:8001';

  String _baseUrl = valorPorDefecto;

  String get baseUrl => _baseUrl;

  /// URL efectiva: en web sí se puede hablar con localhost directamente.
  String get baseUrlEfectiva {
    if (kIsWeb && _baseUrl == valorPorDefecto) return sugerenciaLocal;
    return _baseUrl;
  }

  Future<void> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    final guardado = prefs.getString(_prefsKey);
    if (guardado != null && guardado.trim().isNotEmpty) {
      _baseUrl = normalizar(guardado);
      notifyListeners();
    }
  }

  Future<void> guardar(String url) async {
    final limpia = normalizar(url);
    _baseUrl = limpia;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, limpia);
    notifyListeners();
  }

  Future<void> restaurarPorDefecto() => guardar(valorPorDefecto);

  /// Acepta lo que la gente realmente escribe ("192.168.0.5:8001",
  /// "http://host/" ) y lo deja en una base usable por Uri.parse.
  static String normalizar(String entrada) {
    var url = entrada.trim();
    if (url.isEmpty) return valorPorDefecto;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.host.isEmpty ||
        uri.hasPort ||
        uri.scheme == 'https') {
      return url;
    }
    return uri.replace(port: 8000).toString();
  }

  /// Valida sin efectos secundarios; devuelve null si está bien o el motivo si no.
  static String? validar(String entrada) {
    if (entrada.trim().isEmpty) return 'Escribí la dirección del servidor';
    final uri = Uri.tryParse(normalizar(entrada));
    if (uri == null || !uri.isAbsolute || uri.host.isEmpty) {
      return 'No parece una dirección válida (ej: 192.168.1.10:8001)';
    }
    return null;
  }
}

/// Atajo para el resto del código, que solo necesita leer la base vigente.
String get apiBaseUrl => ApiConfig.instance.baseUrlEfectiva;
