import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../services/auth_controller.dart';
import '../theme.dart';
import '../widgets/server_sheet.dart';
import '../widgets/ui_kit.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _showPassword = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthController>().login(_emailCtrl.text.trim(), _passwordCtrl.text);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'No se pudo iniciar sesión');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _FondoMarca(),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8, top: 4),
                    child: IconButton(
                      tooltip: 'Servidor',
                      icon: const Icon(Icons.dns_outlined, color: RumboColors.textMid),
                      onPressed: () => mostrarServerSheet(context),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const FadeSlideIn(index: 0, child: _Encabezado()),
                            const SizedBox(height: 34),
                            FadeSlideIn(index: 1, child: _buildFormulario(context)),
                            const SizedBox(height: 20),
                            FadeSlideIn(
                              index: 2,
                              child: Center(
                                child: TextButton(
                                  onPressed: _loading
                                      ? null
                                      : () => Navigator.of(context).push(
                                            RumboPageRoute(builder: (_) => const RegisterScreen()),
                                          ),
                                  child: const Text('¿No tenés cuenta? Registrate'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulario(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: RumboColors.surface,
        borderRadius: BorderRadius.circular(RumboRadii.xl),
        border: Border.all(color: RumboColors.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Iniciá sesión', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            const Text(
              'Entrá con la cuenta que usás en Rumbo.',
              style: TextStyle(color: RumboColors.textLow, fontSize: 13.5),
            ),
            const SizedBox(height: 22),
            if (_error != null) ...[
              InfoBanner(mensaje: _error!),
              const SizedBox(height: 18),
            ],
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline, size: 20),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresá tu email' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: !_showPassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _loading ? null : _submit(),
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                suffixIcon: IconButton(
                  tooltip: _showPassword ? 'Ocultar' : 'Mostrar',
                  icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                ),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Ingresá tu contraseña' : null,
            ),
            const SizedBox(height: 26),
            LoadingButton(
              texto: 'Iniciar sesión',
              textoCargando: 'Entrando...',
              cargando: _loading,
              onPressed: _submit,
              icono: Icons.arrow_forward_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: RumboColors.crimson.withValues(alpha: 0.32),
                blurRadius: 44,
                spreadRadius: 1,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Image.asset('assets/icon/icon_app.png', width: 96, height: 96),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Encontrá tu rumbo',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'Prácticas, pasantías y tu primer empleo,\ncon acompañamiento en el camino.',
          textAlign: TextAlign.center,
          style: TextStyle(color: RumboColors.textMid, fontSize: 14.5, height: 1.5),
        ),
      ],
    );
  }
}

/// Fondo de la pantalla de entrada: tinta de base con un halo marino arriba y
/// uno carmín abajo. Son los tres colores de marca sin necesidad de imágenes.
class _FondoMarca extends StatelessWidget {
  const _FondoMarca();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(color: RumboColors.ink),
      child: Stack(
        children: [
          Positioned(
            top: -160,
            left: -120,
            child: _Halo(color: RumboColors.navy, size: 420, opacity: 0.55),
          ),
          Positioned(
            bottom: -180,
            right: -140,
            child: _Halo(color: RumboColors.crimson, size: 400, opacity: 0.3),
          ),
        ],
      ),
    );
  }
}

class _Halo extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;

  const _Halo({required this.color, required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: opacity), color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
