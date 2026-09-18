import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../services/auth_controller.dart';
import '../theme.dart';
import '../widgets/ui_kit.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _showPassword = false;
  String _role = 'joven';

  @override
  void dispose() {
    _nombreCtrl.dispose();
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
      await context.read<AuthController>().register(
            nombre: _nombreCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            role: _role,
          );
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'No se pudo completar el registro');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esJoven = _role == 'joven';
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FadeSlideIn(
                      index: 0,
                      child: BrandHeader(
                        icono: esJoven ? Icons.rocket_launch_outlined : Icons.volunteer_activism_outlined,
                        titulo: esJoven ? 'Empezá tu camino' : 'Acompañá a alguien',
                        subtitulo: esJoven
                            ? 'Creá tu cuenta para buscar prácticas, pasantías y primeros empleos.'
                            : 'Creá tu cuenta de mentor/a para guiar a jóvenes en su primera oportunidad.',
                      ),
                    ),
                    const SizedBox(height: 26),
                    FadeSlideIn(
                      index: 1,
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'joven',
                            label: Text('Busco trabajo'),
                            icon: Icon(Icons.work_outline, size: 17),
                          ),
                          ButtonSegment(
                            value: 'mentor',
                            label: Text('Soy mentor/a'),
                            icon: Icon(Icons.people_outline, size: 17),
                          ),
                        ],
                        selected: {_role},
                        showSelectedIcon: false,
                        onSelectionChanged: (s) => setState(() => _role = s.first),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_error != null) ...[
                      InfoBanner(mensaje: _error!),
                      const SizedBox(height: 18),
                    ],
                    FadeSlideIn(
                      index: 2,
                      child: TextFormField(
                        controller: _nombreCtrl,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Nombre completo',
                          prefixIcon: Icon(Icons.person_outline, size: 20),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresá tu nombre' : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeSlideIn(
                      index: 3,
                      child: TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.mail_outline, size: 20),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresá tu email' : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeSlideIn(
                      index: 4,
                      child: TextFormField(
                        controller: _passwordCtrl,
                        obscureText: !_showPassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _loading ? null : _submit(),
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          helperText: 'Mínimo 8 caracteres',
                          helperStyle: const TextStyle(color: RumboColors.textLow, fontSize: 12),
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _showPassword = !_showPassword),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Ingresá una contraseña';
                          if (v.length < 8) return 'Debe tener al menos 8 caracteres';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 28),
                    FadeSlideIn(
                      index: 5,
                      child: LoadingButton(
                        texto: 'Crear cuenta',
                        textoCargando: 'Creando...',
                        cargando: _loading,
                        onPressed: _submit,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
