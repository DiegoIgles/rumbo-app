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
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: RumboColors.ink,
      systemNavigationBarIconBrightness: Brightness.dark,
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
///
/// El splash se muestra al menos 5 segundos (aunque el bootstrap termine
/// antes), tiempo que se aprovecha para mostrar un mensaje de
/// concientización ambiental.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _minDelayDone = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _minDelayDone = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final showSplash = !_minDelayDone || auth.status == AuthStatus.loading;

    Widget child;
    if (showSplash) {
      child = const _SplashScreen(key: ValueKey('splash'));
    } else if (auth.status == AuthStatus.signedIn) {
      child = const HomeShell(key: ValueKey('home'));
    } else {
      child = const LoginScreen(key: ValueKey('login'));
    }

    return AnimatedSwitcher(
      duration: RumboMotion.slow,
      switchInCurve: RumboMotion.decelerate,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: child,
    );
  }
}

/// Pantalla de arranque: el logo respira mientras se valida el token guardado.
class _SplashScreen extends StatefulWidget {
  const _SplashScreen({super.key});

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
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
                          color: RumboColors.crimson.withValues(
                            alpha: 0.18 + t * 0.22,
                          ),
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
                child: Image.asset(
                  'assets/icon/icon_app.png',
                  width: 104,
                  height: 104,
                ),
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
            const SizedBox(height: 28),
            SizedBox(
              width: 260,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(Icons.eco_rounded, size: 15, color: RumboColors.success),
                  ),
                  const SizedBox(width: 6),
                  const Flexible(
                    child: Text(
                      'Postulate sin papel: tu proceso es 100% digital.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: RumboColors.textMid,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
