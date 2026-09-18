// Formateo de fechas compartido. Se concentra acá para que toda la app
// muestre las fechas igual y para no repetir los padLeft en cada pantalla.

const List<String> _mesesCortos = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

const List<String> _mesesCapitalizados = [
  'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
  'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
];

String dosDigitos(int n) => n.toString().padLeft(2, '0');

/// 07/03/2026
String fechaCorta(DateTime d) => '${dosDigitos(d.day)}/${dosDigitos(d.month)}/${d.year}';

/// 07/03/2026 a partir del ISO que devuelve el backend. Si no parsea, devuelve
/// el texto original en vez de romper la pantalla.
String fechaCortaIso(String iso) {
  final d = DateTime.tryParse(iso);
  return d == null ? iso : fechaCorta(d.toLocal());
}

/// Mar 2026
String mesAnio(DateTime d) => '${_mesesCapitalizados[d.month - 1]} ${d.year}';

/// 7 mar · 15:30
String fechaHora(DateTime d) {
  final local = d.toLocal();
  return '${local.day} ${_mesesCortos[local.month - 1]} · ${dosDigitos(local.hour)}:${dosDigitos(local.minute)}';
}

/// "hace 2 h", "ayer", "hace 3 d". Para listas donde importa la cercanía y no
/// la fecha exacta (mensajes, check-ins recientes).
String haceCuanto(DateTime d) {
  final diff = DateTime.now().difference(d.toLocal());
  if (diff.inMinutes < 1) return 'recién';
  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'hace ${diff.inHours} h';
  if (diff.inDays == 1) return 'ayer';
  if (diff.inDays < 7) return 'hace ${diff.inDays} d';
  return fechaCorta(d.toLocal());
}

String haceCuantoIso(String iso) {
  final d = DateTime.tryParse(iso);
  return d == null ? iso : haceCuanto(d);
}
