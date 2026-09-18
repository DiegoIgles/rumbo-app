import 'package:flutter/foundation.dart' show kIsWeb;

/// URL base del backend (FastAPI).
///
/// - Web / desktop (misma máquina que corre el backend): localhost.
/// - Celular físico (Android/iOS) por Wi-Fi: la IP local de la laptop en la
///   red Wi-Fi (`ipconfig` -> adaptador Wi-Fi -> IPv4). Se actualiza acá si
///   cambia la IP o la red.
/// - Emulador Android: si volvés a usarlo en vez del celular físico, cambiá
///   esto por 'http://10.0.2.2:$_apiPort'.
const String _apiPort = '8001';
const String _lanIp = '10.253.6.7';

String get apiBaseUrl {
  if (kIsWeb) return 'http://localhost:$_apiPort';
  return 'http://$_lanIp:$_apiPort';
}
