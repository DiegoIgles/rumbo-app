import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../theme.dart';
import 'ui_kit.dart';

/// Hoja para apuntar la app a otro backend sin recompilar.
///
/// Existe porque la dirección del servidor estaba escrita a fuego en el código:
/// cualquier APK distribuido solo funcionaba en la red del equipo. Acá se puede
/// cambiar y, sobre todo, *probar* antes de guardar, que es lo que evita el
/// clásico "no me deja entrar" cuando en realidad la IP cambió.
Future<void> mostrarServerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ServerSheet(),
  );
}

class _ServerSheet extends StatefulWidget {
  const _ServerSheet();

  @override
  State<_ServerSheet> createState() => _ServerSheetState();
}

enum _EstadoPrueba { inicial, probando, ok, fallo }

class _ServerSheetState extends State<_ServerSheet> {
  late final TextEditingController _ctrl = TextEditingController(
    text: ApiConfig.instance.baseUrl,
  );
  _EstadoPrueba _estado = _EstadoPrueba.inicial;
  String? _detalle;
  String? _errorCampo;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _probar() async {
    final motivo = ApiConfig.validar(_ctrl.text);
    if (motivo != null) {
      setState(() => _errorCampo = motivo);
      return;
    }
    setState(() {
      _errorCampo = null;
      _estado = _EstadoPrueba.probando;
      _detalle = null;
    });
    final base = ApiConfig.normalizar(_ctrl.text);
    try {
      final r = await http
          .get(Uri.parse('$base/health'))
          .timeout(const Duration(seconds: 6));
      if (!mounted) return;
      if (r.statusCode == 200) {
        setState(() {
          _estado = _EstadoPrueba.ok;
          _detalle = 'El servidor respondió correctamente.';
        });
      } else {
        setState(() {
          _estado = _EstadoPrueba.fallo;
          _detalle =
              'Respondió con código ${r.statusCode}. ¿Es un servidor de Rumbo?';
        });
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _estado = _EstadoPrueba.fallo;
        _detalle =
            'No respondió a tiempo. Si es celular físico, usá Wi-Fi de la misma red o activá ADB reverse.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _estado = _EstadoPrueba.fallo;
        _detalle = 'No se pudo conectar con $base. Detalle: ${e.runtimeType}.';
      });
    }
  }

  Future<void> _guardar() async {
    final motivo = ApiConfig.validar(_ctrl.text);
    if (motivo != null) {
      setState(() => _errorCampo = motivo);
      return;
    }
    await ApiConfig.instance.guardar(_ctrl.text);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Servidor: ${ApiConfig.instance.baseUrl}')),
    );
  }

  void _usarSugerencia(String url) {
    setState(() {
      _ctrl.text = url;
      _estado = _EstadoPrueba.inicial;
      _detalle = null;
      _errorCampo = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: RumboColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(RumboRadii.xl),
          ),
          border: Border(top: BorderSide(color: RumboColors.outline)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: RumboColors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const SectionTitle('Servidor de Rumbo'),
              const SizedBox(height: 8),
              const Text(
                'La app se conecta al backend en esta dirección. Cambiala si el '
                'servidor está en otra máquina, si cambió la IP de la red o si '
                'estás probando con un celular conectado por USB.',
                style: TextStyle(
                  color: RumboColors.textMid,
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _ctrl,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'Dirección',
                  hintText: '192.168.1.10:8001',
                  errorText: _errorCampo,
                  prefixIcon: const Icon(Icons.link, size: 20),
                ),
                onChanged: (_) {
                  if (_estado != _EstadoPrueba.inicial || _errorCampo != null) {
                    setState(() {
                      _estado = _EstadoPrueba.inicial;
                      _detalle = null;
                      _errorCampo = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Sugerencia(
                    etiqueta: 'USB ADB',
                    onTap: () => _usarSugerencia(ApiConfig.sugerenciaUsb),
                  ),
                  _Sugerencia(
                    etiqueta: 'Wi-Fi laptop',
                    onTap: () =>
                        _usarSugerencia(ApiConfig.sugerenciaWifiLaptop),
                  ),
                  _Sugerencia(
                    etiqueta: 'Emulador',
                    onTap: () => _usarSugerencia(ApiConfig.sugerenciaEmulador),
                  ),
                  _Sugerencia(
                    etiqueta: 'PC local',
                    onTap: () => _usarSugerencia(ApiConfig.sugerenciaLocal),
                  ),
                  _Sugerencia(
                    etiqueta: 'Puerto 8001',
                    onTap: () =>
                        _usarSugerencia(ApiConfig.sugerenciaPuertoAlterno),
                  ),
                ],
              ),
              if (_detalle != null) ...[
                const SizedBox(height: 16),
                InfoBanner(
                  mensaje: _detalle!,
                  tono: _estado == _EstadoPrueba.ok
                      ? BannerTono.exito
                      : BannerTono.error,
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _estado == _EstadoPrueba.probando
                          ? null
                          : _probar,
                      icon: _estado == _EstadoPrueba.probando
                          ? const SizedBox(
                              height: 15,
                              width: 15,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.wifi_tethering, size: 18),
                      label: Text(
                        _estado == _EstadoPrueba.probando
                            ? 'Probando...'
                            : 'Probar',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _guardar,
                      child: const Text('Guardar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Sugerencia extends StatelessWidget {
  final String etiqueta;
  final VoidCallback onTap;

  const _Sugerencia({required this.etiqueta, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: RumboColors.navyRaised,
          borderRadius: RumboRadii.pill,
          border: Border.all(
            color: RumboColors.navyBright.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          etiqueta,
          style: const TextStyle(
            color: RumboColors.navyBright,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
