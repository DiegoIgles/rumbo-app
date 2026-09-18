import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_constants.dart';
import '../config.dart';
import '../models/experiencia.dart';
import '../models/profile.dart';
import '../services/api_client.dart';
import '../services/auth_controller.dart';
import '../theme.dart';
import '../utils/formato.dart';
import '../widgets/server_sheet.dart';
import '../widgets/ui_kit.dart';
import 'experiencia_form_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => ProfileTabState();
}

class ProfileTabState extends State<ProfileTab> {
  final _edadCtrl = TextEditingController();
  String? _sectorInteres;
  String? _nivelExperiencia;
  String _rutaPreferida = 'ambas';

  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _mensajeGuardado;

  List<Experiencia>? _experiencias;
  bool _cargandoExperiencia = true;
  String? _errorExperiencia;

  @override
  void initState() {
    super.initState();
    _load();
    _cargarExperiencia();
  }

  @override
  void dispose() {
    _edadCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await context.read<AuthController>().api.getProfile();
      if (profile != null) {
        _edadCtrl.text = profile.edad?.toString() ?? '';
        _sectorInteres = areas.contains(profile.sectorInteres) ? profile.sectorInteres : null;
        _nivelExperiencia =
            nivelesExperiencia.contains(profile.nivelExperiencia) ? profile.nivelExperiencia : null;
        _rutaPreferida = profile.rutaPreferida;
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo cargar tu perfil');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cargarExperiencia() async {
    setState(() {
      _cargandoExperiencia = true;
      _errorExperiencia = null;
    });
    try {
      final experiencias = await context.read<AuthController>().api.listarExperiencia();
      if (mounted) setState(() => _experiencias = experiencias);
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorExperiencia = e.message);
    } catch (_) {
      if (mounted) setState(() => _errorExperiencia = 'No se pudo cargar tu experiencia');
    } finally {
      if (mounted) setState(() => _cargandoExperiencia = false);
    }
  }

  Future<void> _abrirFormExperiencia({Experiencia? experiencia}) async {
    final guardado = await Navigator.of(context).push<bool>(
      RumboPageRoute(builder: (_) => ExperienciaFormScreen(experiencia: experiencia)),
    );
    if (guardado == true) _cargarExperiencia();
  }

  Future<void> _confirmarEliminarExperiencia(Experiencia experiencia) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar experiencia'),
        content: Text('¿Eliminar "${experiencia.puesto}" en ${experiencia.empresa}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: RumboColors.danger),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    try {
      await context.read<AuthController>().api.eliminarExperiencia(experiencia.id);
      _cargarExperiencia();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo eliminar')));
      }
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _mensajeGuardado = null;
      _error = null;
    });
    try {
      await context.read<AuthController>().api.upsertProfile(
            AppProfile(
              edad: int.tryParse(_edadCtrl.text),
              sectorInteres: _sectorInteres,
              nivelExperiencia: _nivelExperiencia,
              rutaPreferida: _rutaPreferida,
            ),
          );
      if (mounted) setState(() => _mensajeGuardado = 'Perfil actualizado.');
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo guardar tu perfil');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmarLogout() async {
    final salir = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('Vas a tener que volver a ingresar tu email y contraseña.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: RumboColors.danger),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (salir == true && mounted) {
      await context.read<AuthController>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.user;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const SkeletonList(cantidad: 3, padding: EdgeInsets.fromLTRB(20, 20, 20, 110))
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
                children: [
                  FadeSlideIn(
                    index: 0,
                    child: _CabeceraPerfil(
                      nombre: user?.nombre ?? '',
                      email: user?.email ?? '',
                      rol: auth.role ?? 'joven',
                      onLogout: _confirmarLogout,
                    ),
                  ),
                  const SizedBox(height: 26),
                  const FadeSlideIn(index: 1, child: SectionTitle('Tus datos')),
                  const SizedBox(height: 14),
                  if (_error != null) ...[
                    InfoBanner(mensaje: _error!),
                    const SizedBox(height: 14),
                  ],
                  if (_mensajeGuardado != null) ...[
                    InfoBanner(mensaje: _mensajeGuardado!, tono: BannerTono.exito),
                    const SizedBox(height: 14),
                  ],
                  FadeSlideIn(
                    index: 2,
                    child: TextField(
                      controller: _edadCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Edad',
                        prefixIcon: Icon(Icons.cake_outlined, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeSlideIn(
                    index: 3,
                    child: DropdownButtonFormField<String?>(
                      key: ValueKey('sector-$_sectorInteres'),
                      initialValue: _sectorInteres,
                      isExpanded: true,
                      dropdownColor: RumboColors.surfaceRaised,
                      decoration: const InputDecoration(
                        labelText: 'Sector de interés',
                        prefixIcon: Icon(Icons.category_outlined, size: 20),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Sin definir')),
                        ...areas.map((a) => DropdownMenuItem(value: a, child: Text(a))),
                      ],
                      onChanged: (v) => setState(() => _sectorInteres = v),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeSlideIn(
                    index: 4,
                    child: DropdownButtonFormField<String?>(
                      key: ValueKey('nivel-$_nivelExperiencia'),
                      initialValue: _nivelExperiencia,
                      isExpanded: true,
                      dropdownColor: RumboColors.surfaceRaised,
                      decoration: const InputDecoration(
                        labelText: 'Nivel de experiencia',
                        prefixIcon: Icon(Icons.stairs_outlined, size: 20),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Sin definir')),
                        ...nivelesExperiencia.map((n) => DropdownMenuItem(value: n, child: Text(n))),
                      ],
                      onChanged: (v) => setState(() => _nivelExperiencia = v),
                    ),
                  ),
                  const SizedBox(height: 22),
                  FadeSlideIn(
                    index: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ruta preferida',
                          style: TextStyle(color: RumboColors.textMid, fontSize: 13.5, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),
                        SegmentedButton<String>(
                          segments: rutaLabels.entries
                              .map((e) => ButtonSegment(value: e.key, label: Text(e.value)))
                              .toList(),
                          selected: {_rutaPreferida},
                          showSelectedIcon: false,
                          onSelectionChanged: (s) => setState(() => _rutaPreferida = s.first),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  FadeSlideIn(
                    index: 6,
                    child: LoadingButton(
                      texto: 'Guardar cambios',
                      textoCargando: 'Guardando...',
                      cargando: _saving,
                      onPressed: _save,
                    ),
                  ),
                  const SizedBox(height: 36),
                  FadeSlideIn(index: 7, child: _buildExperienciaSection(context)),
                  const SizedBox(height: 32),
                  FadeSlideIn(index: 8, child: _buildAjustes(context)),
                ],
              ),
      ),
    );
  }

  Widget _buildExperienciaSection(BuildContext context) {
    final experiencias = _experiencias ?? const <Experiencia>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          'Experiencia laboral',
          accion: TextButton.icon(
            onPressed: () => _abrirFormExperiencia(),
            icon: const Icon(Icons.add_rounded, size: 17),
            label: const Text('Agregar'),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Si ya trabajaste antes, contá en qué y cuándo.',
          style: TextStyle(color: RumboColors.textLow, fontSize: 13),
        ),
        const SizedBox(height: 14),
        if (_cargandoExperiencia)
          const SkeletonCard(lineas: 2)
        else if (_errorExperiencia != null)
          InfoBanner(mensaje: _errorExperiencia!)
        else if (experiencias.isEmpty)
          RumboCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 26),
            child: Column(
              children: [
                const Icon(Icons.work_history_outlined, color: RumboColors.textLow, size: 26),
                const SizedBox(height: 12),
                const Text(
                  'Todavía no agregaste experiencia laboral.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: RumboColors.textMid, fontSize: 13.5),
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: () => _abrirFormExperiencia(),
                  child: const Text('Agregar la primera'),
                ),
              ],
            ),
          )
        else
          for (var i = 0; i < experiencias.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _ExperienciaCard(
              experiencia: experiencias[i],
              onEdit: () => _abrirFormExperiencia(experiencia: experiencias[i]),
              onDelete: () => _confirmarEliminarExperiencia(experiencias[i]),
            ),
          ],
      ],
    );
  }

  Widget _buildAjustes(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Ajustes'),
        const SizedBox(height: 14),
        RumboCard(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.dns_outlined),
                title: const Text('Servidor'),
                subtitle: Text(
                  context.watch<ApiConfig>().baseUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => mostrarServerSheet(context),
              ),
              const Divider(indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: RumboColors.danger),
                title: const Text('Cerrar sesión', style: TextStyle(color: RumboColors.danger)),
                onTap: _confirmarLogout,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CabeceraPerfil extends StatelessWidget {
  final String nombre;
  final String email;
  final String rol;
  final VoidCallback onLogout;

  const _CabeceraPerfil({
    required this.nombre,
    required this.email,
    required this.rol,
    required this.onLogout,
  });

  /// Iniciales para el avatar: primera letra del nombre y del apellido.
  String get _iniciales {
    final partes = nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return (partes.first.substring(0, 1) + partes[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: RumboColors.navyGradient,
        borderRadius: BorderRadius.circular(RumboRadii.xl),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
            ),
            child: Text(
              _iniciales,
              style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 17.5, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12.8),
                ),
                const SizedBox(height: 9),
                RumboTag(
                  texto: rol == 'mentor' ? 'Mentor/a' : 'Buscando oportunidad',
                  color: Colors.white,
                  icono: rol == 'mentor' ? Icons.volunteer_activism_outlined : Icons.explore_outlined,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 20),
            onPressed: onLogout,
          ),
        ],
      ),
    );
  }
}

class _ExperienciaCard extends StatelessWidget {
  final Experiencia experiencia;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExperienciaCard({
    required this.experiencia,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final e = experiencia;
    final rango = e.esActual
        ? '${mesAnio(e.fechaInicio)} — Actualidad'
        : '${mesAnio(e.fechaInicio)} — ${mesAnio(e.fechaFin!)}';

    return RumboCard(
      padding: const EdgeInsets.all(15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: RumboColors.navyBright.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(RumboRadii.sm),
            ),
            child: const Icon(Icons.business_center_outlined, color: RumboColors.navyBright, size: 19),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.puesto, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  e.empresa,
                  style: const TextStyle(color: RumboColors.textMid, fontSize: 13.5),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    MetaRow(icono: Icons.calendar_today_outlined, texto: rango),
                    if (e.esActual) ...[
                      const SizedBox(width: 8),
                      const RumboTag(texto: 'Actual', color: RumboColors.success),
                    ],
                  ],
                ),
                if (e.referencia != null && e.referencia!.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  MetaRow(icono: Icons.contact_phone_outlined, texto: e.referencia!),
                ],
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: onEdit,
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: RumboColors.danger),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
