import 'package:flutter/material.dart';

import 'crecimiento_tab.dart';
import 'inicio_tab.dart';
import 'profile_tab.dart';
import 'recomendadas_tab.dart';
import 'vacantes_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  // Solo la pestaña inicial arranca "visitada": las demás se construyen (y
  // recién ahí disparan sus pedidos a la API) la primera vez que se abren,
  // en vez de las 5 a la vez apenas se inicia sesión.
  final Set<int> _visitadas = {0};

  void _goToPerfil() => setState(() {
        _index = 4;
        _visitadas.add(4);
      });

  void _seleccionar(int i) => setState(() {
        _index = i;
        _visitadas.add(i);
      });

  @override
  Widget build(BuildContext context) {
    final builders = <WidgetBuilder>[
      (_) => const InicioTab(),
      (_) => const VacantesTab(),
      (_) => RecomendadasTab(onIrAPerfil: _goToPerfil),
      (_) => const CrecimientoTab(),
      (_) => const ProfileTab(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          for (var i = 0; i < builders.length; i++)
            _visitadas.contains(i) ? builders[i](context) : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _seleccionar,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.work_outline), selectedIcon: Icon(Icons.work), label: 'Vacantes'),
          NavigationDestination(
            icon: Icon(Icons.recommend_outlined),
            selectedIcon: Icon(Icons.recommend),
            label: 'Recomendadas',
          ),
          NavigationDestination(icon: Icon(Icons.rocket_launch_outlined), selectedIcon: Icon(Icons.rocket_launch), label: 'Crecimiento'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
