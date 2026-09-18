import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'config.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'services/auth_controller.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // La URL del backend tiene que estar resuelta antes del primer pedido a la
  // API, así que se lee acá y no dentro de un FutureBuilder.
  await ApiConfig.instance.cargar();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: RumboColors.ink,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const RumboApp());
}

class RumboApp extends StatelessWidget {
  const RumboApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()..bootstrap()),
        ChangeNotifierProvider.value(value: ApiConfig.instance),
      ],
      child: MaterialApp(
        title: 'Rumbo',
        debugShowCheckedModeBanner: false,
        theme: buildRumboTheme(),
        home: const AuthGate(),
      ),
    );
  }
}

/// Decide qué se ve según el estado de sesión. El cambio entre pantallas se
/// hace con un fundido para que no haya un salto brusco al terminar el
/// bootstrap o al cerrar sesión.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return AnimatedSwitcher(
      duration: RumboMotion.slow,
      switchInCurve: RumboMotion.decelerate,
      transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
      child: switch (auth.status) {
        AuthStatus.loading => const _SplashScreen(key: ValueKey('splash')),
        AuthStatus.signedIn => const HomeShell(key: ValueKey('home')),
        AuthStatus.signedOut => const LoginScreen(key: ValueKey('login')),
      },
    );
  }
}

/// Pantalla de arranque: el logo respira mientras se valida el token guardado.
class _SplashScreen extends StatefulWidget {
  const _SplashScreen({super.key});

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RumboColors.ink,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final t = Curves.easeInOut.transform(_controller.value);
                return Transform.scale(
                  scale: 0.96 + t * 0.06,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: RumboColors.crimson.withValues(alpha: 0.18 + t * 0.22),
                          blurRadius: 40,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: child,
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Image.asset('assets/icon/icon_app.png', width: 104, height: 104),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'RUMBO',
              style: TextStyle(
                color: RumboColors.textHigh,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 6,
              ),
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: 120,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: const LinearProgressIndicator(minHeight: 3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
