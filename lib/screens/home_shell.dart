import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
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

  void _goToPerfil() => _seleccionar(4);

  void _seleccionar(int i) {
    if (i == _index) return;
    HapticFeedback.selectionClick();
    setState(() {
      _index = i;
      _visitadas.add(i);
    });
  }

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
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: [
          for (var i = 0; i < builders.length; i++)
            _visitadas.contains(i) ? builders[i](context) : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: _RumboNavBar(
        index: _index,
        onSeleccionar: _seleccionar,
        items: const [
          _NavItem(Icons.home_outlined, Icons.home_rounded, 'Inicio'),
          _NavItem(Icons.work_outline, Icons.work_rounded, 'Vacantes'),
          _NavItem(Icons.auto_awesome_outlined, Icons.auto_awesome, 'Para vos'),
          _NavItem(Icons.rocket_launch_outlined, Icons.rocket_launch, 'Crecimiento'),
          _NavItem(Icons.person_outline, Icons.person_rounded, 'Perfil'),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icono;
  final IconData iconoActivo;
  final String etiqueta;

  const _NavItem(this.icono, this.iconoActivo, this.etiqueta);
}

/// Barra inferior propia en vez de NavigationBar de Material.
///
/// La de Material reserva espacio para la etiqueta de las cinco pestañas a la
/// vez, y con cinco destinos en pantallas angostas las etiquetas se cortan.
/// Acá la etiqueta aparece solo en la pestaña activa, que además se expande en
/// una píldora: entra cómodo en cualquier ancho y da el feedback de selección.
class _RumboNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSeleccionar;
  final List<_NavItem> items;

  const _RumboNavBar({required this.index, required this.onSeleccionar, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xF21F1F1F),
        border: Border(top: BorderSide(color: RumboColors.outlineSoft)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < items.length; i++)
                Flexible(
                  child: _NavBoton(
                    item: items[i],
                    activo: i == index,
                    onTap: () => onSeleccionar(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBoton extends StatelessWidget {
  final _NavItem item;
  final bool activo;
  final VoidCallback onTap;

  const _NavBoton({required this.item, required this.activo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: RumboMotion.medium,
        curve: RumboMotion.emphasized,
        padding: EdgeInsets.symmetric(horizontal: activo ? 14 : 10, vertical: 9),
        decoration: BoxDecoration(
          color: activo ? RumboColors.crimson : Colors.transparent,
          borderRadius: RumboRadii.pill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: RumboMotion.fast,
              child: Icon(
                activo ? item.iconoActivo : item.icono,
                key: ValueKey(activo),
                size: 21,
                color: activo ? Colors.white : RumboColors.textLow,
              ),
            ),
            // La etiqueta crece de 0 a su ancho natural en vez de aparecer de
            // golpe, así el resto de las pestañas se corren con suavidad.
            ClipRect(
              child: AnimatedAlign(
                duration: RumboMotion.medium,
                curve: RumboMotion.emphasized,
                alignment: Alignment.centerLeft,
                widthFactor: activo ? 1 : 0,
                child: AnimatedOpacity(
                  duration: RumboMotion.fast,
                  opacity: activo ? 1 : 0,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      item.etiqueta,
                      maxLines: 1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
