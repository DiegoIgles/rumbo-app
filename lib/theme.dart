import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Sistema de diseño de Rumbo.
///
/// Tres colores de marca mandan sobre todo lo demás:
///   #1F1F1F  tinta   — el fondo de la app
///   #A51C30  carmín  — la acción principal
///   #293352  marino  — el color de apoyo
///
/// El resto de los tokens se derivan de esos tres. Los sufijos `Bright` son
/// versiones aclaradas que existen solo por contraste: el carmín y el marino
/// puros son demasiado oscuros para texto o iconos sobre el fondo #1F1F1F.
class RumboColors {
  const RumboColors._();

  // ---- Marca ----
  static const Color ink = Color(0xFF1F1F1F);
  static const Color crimson = Color(0xFFA51C30);
  static const Color navy = Color(0xFF293352);

  // ---- Superficies (elevación por luminosidad, no por sombra) ----
  static const Color surface = Color(0xFF242424);
  static const Color surfaceRaised = Color(0xFF2B2B2B);
  static const Color surfaceHigh = Color(0xFF343434);
  static const Color outline = Color(0xFF3A3A3A);
  static const Color outlineSoft = Color(0xFF2F2F2F);

  // ---- Acentos legibles sobre oscuro ----
  static const Color crimsonBright = Color(0xFFE34A5F);
  static const Color crimsonSoft = Color(0xFF6E1421);
  static const Color navyBright = Color(0xFF8593CE);
  static const Color navyRaised = Color(0xFF33406A);

  // ---- Texto ----
  static const Color textHigh = Color(0xFFF4F2F1);
  static const Color textMid = Color(0xFFB2ACAA);
  static const Color textLow = Color(0xFF807A78);

  // ---- Semánticos ----
  static const Color success = Color(0xFF3FBF88);
  static const Color successSoft = Color(0xFF12301F);
  static const Color warning = Color(0xFFE0A33E);
  static const Color warningSoft = Color(0xFF332611);
  static const Color danger = Color(0xFFE5524B);
  static const Color dangerSoft = Color(0xFF331917);

  /// Degradado de marca: del marino al carmín. Se usa en cabeceras y en el
  /// splash de login para que las dos marcas convivan sin competir.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navy, crimson],
  );

  static const LinearGradient navyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF33406A), navy],
  );

  /// Velo que se pone sobre el degradado para que el texto blanco encima
  /// mantenga contraste aunque el degradado sea claro en una esquina.
  static const LinearGradient scrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0xCC1F1F1F)],
  );
}

/// Curvas y duraciones únicas para toda la app: si todas las transiciones usan
/// el mismo par, la app "se siente" de una sola pieza.
class RumboMotion {
  const RumboMotion._();

  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 520);

  /// Salida rápida, llegada suave: es la curva estándar de Material 3.
  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.0);
  static const Curve decelerate = Cubic(0.05, 0.7, 0.1, 1.0);
  static const Curve spring = Curves.easeOutBack;
}

class RumboRadii {
  const RumboRadii._();

  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;

  static final BorderRadius card = BorderRadius.circular(lg);
  static final BorderRadius field = BorderRadius.circular(md);
  static final BorderRadius pill = BorderRadius.circular(999);
}

/// Transición compartida por todas las rutas: un fade combinado con un
/// desplazamiento corto hacia arriba. Reemplaza al slide lateral por defecto
/// de Android, que se siente más brusco.
class RumboPageRoute<T> extends PageRouteBuilder<T> {
  RumboPageRoute({required WidgetBuilder builder, super.settings})
      : super(
          transitionDuration: RumboMotion.medium,
          reverseTransitionDuration: RumboMotion.fast,
          pageBuilder: (context, _, _) => builder(context),
          transitionsBuilder: (context, animation, _, child) {
            final curved = CurvedAnimation(parent: animation, curve: RumboMotion.emphasized);
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.035), end: Offset.zero).animate(curved),
                child: child,
              ),
            );
          },
        );
}

ThemeData buildRumboTheme() {
  const colorScheme = ColorScheme.dark(
    primary: RumboColors.crimson,
    onPrimary: Colors.white,
    primaryContainer: RumboColors.crimsonSoft,
    onPrimaryContainer: RumboColors.crimsonBright,
    secondary: RumboColors.navy,
    onSecondary: Colors.white,
    secondaryContainer: RumboColors.navyRaised,
    onSecondaryContainer: RumboColors.navyBright,
    surface: RumboColors.ink,
    onSurface: RumboColors.textHigh,
    surfaceContainerLowest: RumboColors.ink,
    surfaceContainerLow: RumboColors.surface,
    surfaceContainer: RumboColors.surface,
    surfaceContainerHigh: RumboColors.surfaceRaised,
    surfaceContainerHighest: RumboColors.surfaceHigh,
    onSurfaceVariant: RumboColors.textMid,
    outline: RumboColors.outline,
    outlineVariant: RumboColors.outlineSoft,
    error: RumboColors.danger,
    onError: Colors.white,
    errorContainer: RumboColors.dangerSoft,
    onErrorContainer: RumboColors.danger,
  );

  final base = ThemeData(useMaterial3: true, colorScheme: colorScheme, brightness: Brightness.dark);

  return base.copyWith(
    scaffoldBackgroundColor: RumboColors.ink,
    canvasColor: RumboColors.ink,
    splashFactory: InkSparkle.splashFactory,
    textTheme: _buildTextTheme(base.textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: RumboColors.ink,
      foregroundColor: RumboColors.textHigh,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      titleTextStyle: TextStyle(
        color: RumboColors.textHigh,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: RumboColors.surface,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: RumboRadii.card,
        side: const BorderSide(color: RumboColors.outlineSoft),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: RumboColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(color: RumboColors.textLow),
      labelStyle: const TextStyle(color: RumboColors.textMid),
      floatingLabelStyle: const TextStyle(color: RumboColors.crimsonBright, fontWeight: FontWeight.w600),
      prefixIconColor: RumboColors.textLow,
      suffixIconColor: RumboColors.textLow,
      border: OutlineInputBorder(
        borderRadius: RumboRadii.field,
        borderSide: const BorderSide(color: RumboColors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: RumboRadii.field,
        borderSide: const BorderSide(color: RumboColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: RumboRadii.field,
        borderSide: const BorderSide(color: RumboColors.crimsonBright, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: RumboRadii.field,
        borderSide: const BorderSide(color: RumboColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: RumboRadii.field,
        borderSide: const BorderSide(color: RumboColors.danger, width: 1.6),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: RumboColors.crimson,
        foregroundColor: Colors.white,
        disabledBackgroundColor: RumboColors.surfaceHigh,
        disabledForegroundColor: RumboColors.textLow,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
        shape: RoundedRectangleBorder(borderRadius: RumboRadii.field),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.1),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: RumboColors.textHigh,
        disabledForegroundColor: RumboColors.textLow,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        side: const BorderSide(color: RumboColors.outline),
        shape: RoundedRectangleBorder(borderRadius: RumboRadii.field),
        textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: RumboColors.crimsonBright,
        textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: RumboColors.textMid),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? RumboColors.crimson : RumboColors.surface,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? Colors.white : RumboColors.textMid,
        ),
        side: WidgetStateProperty.all(const BorderSide(color: RumboColors.outline)),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: RumboRadii.field)),
        textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 12, horizontal: 10)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: RumboColors.surfaceRaised,
      side: const BorderSide(color: RumboColors.outline),
      labelStyle: const TextStyle(color: RumboColors.textMid, fontSize: 12, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: RumboRadii.pill),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    ),
    dividerTheme: const DividerThemeData(color: RumboColors.outlineSoft, thickness: 1, space: 1),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: RumboColors.crimsonBright,
      linearTrackColor: RumboColors.surfaceHigh,
      circularTrackColor: Colors.transparent,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: RumboColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RumboRadii.lg)),
      titleTextStyle: const TextStyle(color: RumboColors.textHigh, fontSize: 18, fontWeight: FontWeight.w700),
      contentTextStyle: const TextStyle(color: RumboColors.textMid, fontSize: 14.5, height: 1.45),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: RumboColors.surfaceHigh,
      contentTextStyle: const TextStyle(color: RumboColors.textHigh, fontSize: 14),
      actionTextColor: RumboColors.crimsonBright,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: RumboRadii.field),
      insetPadding: const EdgeInsets.all(16),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: RumboColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(RumboRadii.xl)),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: RumboColors.textHigh,
      unselectedLabelColor: RumboColors.textLow,
      indicatorColor: RumboColors.crimsonBright,
      dividerColor: RumboColors.outlineSoft,
      labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    ),
    listTileTheme: const ListTileThemeData(
      textColor: RumboColors.textHigh,
      iconColor: RumboColors.textMid,
      subtitleTextStyle: TextStyle(color: RumboColors.textMid, fontSize: 13, height: 1.35),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? RumboColors.crimson : Colors.transparent,
      ),
      side: const BorderSide(color: RumboColors.outline, width: 1.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStateProperty.all(RumboColors.surfaceRaised),
        surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(RumboRadii.md)),
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: RumboColors.crimson,
      foregroundColor: Colors.white,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: RoundedRectangleBorder(borderRadius: RumboRadii.pill),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: RumboColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RumboRadii.lg)),
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: RumboColors.surfaceRaised,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RumboRadii.lg)),
    ),
    // Las rutas de la app usan RumboPageRoute; esto cubre las que empuja el
    // propio framework (diálogos de fecha/hora, por ejemplo).
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: FadeUpwardsPageTransitionsBuilder()},
    ),
  );
}

TextTheme _buildTextTheme(TextTheme base) {
  return base.copyWith(
    displaySmall: base.displaySmall?.copyWith(
      color: RumboColors.textHigh,
      fontWeight: FontWeight.w800,
      letterSpacing: -1,
    ),
    headlineMedium: base.headlineMedium?.copyWith(
      color: RumboColors.textHigh,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.8,
    ),
    headlineSmall: base.headlineSmall?.copyWith(
      color: RumboColors.textHigh,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
    titleLarge: base.titleLarge?.copyWith(
      color: RumboColors.textHigh,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
    ),
    titleMedium: base.titleMedium?.copyWith(
      color: RumboColors.textHigh,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
    ),
    titleSmall: base.titleSmall?.copyWith(color: RumboColors.textHigh, fontWeight: FontWeight.w600),
    bodyLarge: base.bodyLarge?.copyWith(color: RumboColors.textHigh, height: 1.45),
    bodyMedium: base.bodyMedium?.copyWith(color: RumboColors.textMid, height: 1.5),
    bodySmall: base.bodySmall?.copyWith(color: RumboColors.textLow, height: 1.4),
    labelLarge: base.labelLarge?.copyWith(color: RumboColors.textHigh, fontWeight: FontWeight.w600),
    labelMedium: base.labelMedium?.copyWith(color: RumboColors.textMid, fontWeight: FontWeight.w600),
    labelSmall: base.labelSmall?.copyWith(color: RumboColors.textLow, letterSpacing: 0.6),
  );
}
