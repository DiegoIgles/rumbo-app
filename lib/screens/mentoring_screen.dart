import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_constants.dart';
import '../models/mentoria.dart';
import '../services/api_client.dart';
import '../services/auth_controller.dart';
import '../theme.dart';
import 'mentoria_chat_screen.dart';

class MentoringScreen extends StatefulWidget {
  const MentoringScreen({super.key});

  @override
  State<MentoringScreen> createState() => _MentoringScreenState();
}

class _MentoringScreenState extends State<MentoringScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mentoría'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Mentores'), Tab(text: 'Mis mentorías')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_MentoresTab(), _MisMentoriasTab()],
      ),
    );
  }
}

class _MentoresTab extends StatefulWidget {
  const _MentoresTab();

  @override
  State<_MentoresTab> createState() => _MentoresTabState();
}

class _MentoresTabState extends State<_MentoresTab> {
  String? _area;
  late Future<List<MentorProfile>> _future;
  final Set<String> _solicitando = {};
  final Set<String> _solicitados = {};

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<MentorProfile>> _load() => context.read<AuthController>().api.mentores(area: _area);

  void _reload() => setState(() {
        _future = _load();
      });

  Future<void> _solicitar(MentorProfile mentor) async {
    setState(() => _solicitando.add(mentor.userId));
    try {
      await context.read<AuthController>().api.solicitarMentoria(mentorId: mentor.userId);
      setState(() => _solicitados.add(mentor.userId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Le pediste mentoría a ${mentor.nombre}.')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo enviar la solicitud')));
    } finally {
      if (mounted) setState(() => _solicitando.remove(mentor.userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: DropdownButtonFormField<String?>(
            key: ValueKey(_area),
            initialValue: _area,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Área de expertise', isDense: true),
            items: [
              const DropdownMenuItem(value: null, child: Text('Todas')),
              ...areas.map((a) => DropdownMenuItem(value: a, child: Text(a))),
            ],
            onChanged: (v) {
              _area = v;
              _reload();
            },
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _future;
            },
            child: FutureBuilder<List<MentorProfile>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(snapshot.error is ApiException ? (snapshot.error as ApiException).message : 'Error al cargar mentores'),
                  );
                }
                final mentores = snapshot.data ?? [];
                if (mentores.isEmpty) {
                  return ListView(
                    children: const [SizedBox(height: 60), Center(child: Text('No hay mentores disponibles todavía.'))],
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: mentores.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final m = mentores[i];
                    final yaSolicitado = _solicitados.contains(m.userId);
                    final solicitando = _solicitando.contains(m.userId);
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(backgroundColor: rumboPrimary.withValues(alpha: 0.12), child: Icon(Icons.person, color: rumboPrimary)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(m.nombre, style: const TextStyle(fontWeight: FontWeight.w700)),
                                      Text(m.areaExpertise, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (m.bio != null && m.bio!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(m.bio!),
                            ],
                            if (m.disponibilidad != null && m.disponibilidad!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.schedule, size: 14, color: Colors.black45),
                                  const SizedBox(width: 4),
                                  Text(m.disponibilidad!, style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
                                ],
                              ),
                            ],
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: (yaSolicitado || solicitando) ? null : () => _solicitar(m),
                                child: Text(
                                  yaSolicitado ? 'Solicitud enviada' : (solicitando ? 'Enviando...' : 'Pedir mentoría'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _MisMentoriasTab extends StatefulWidget {
  const _MisMentoriasTab();

  @override
  State<_MisMentoriasTab> createState() => _MisMentoriasTabState();
}

class _MisMentoriasTabState extends State<_MisMentoriasTab> {
  late Future<List<Mentoria>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AuthController>().api.misMentorias();
  }

  void _reload() => setState(() {
        _future = context.read<AuthController>().api.misMentorias();
      });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        _reload();
        await _future;
      },
      child: FutureBuilder<List<Mentoria>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ListView(
              children: [
                const SizedBox(height: 60),
                Center(
                  child: Text(snapshot.error is ApiException ? (snapshot.error as ApiException).message : 'Error al cargar tus mentorías'),
                ),
              ],
            );
          }
          final mentorias = snapshot.data ?? [];
          if (mentorias.isEmpty) {
            return ListView(
              children: const [SizedBox(height: 60), Center(child: Text('Todavía no pediste ninguna mentoría.'))],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: mentorias.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final m = mentorias[i];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: _EstadoIcon(estado: m.estado),
                  title: Text(m.mentorNombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(_estadoLabel(m.estado)),
                  trailing: m.estado == 'aceptada' ? const Icon(Icons.chevron_right) : null,
                  onTap: m.estado == 'aceptada'
                      ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MentoriaChatScreen(mentoria: m)))
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

String _estadoLabel(String estado) {
  switch (estado) {
    case 'aceptada':
      return 'Aceptada — tocá para chatear';
    case 'rechazada':
      return 'Rechazada';
    default:
      return 'Pendiente de respuesta';
  }
}

class _EstadoIcon extends StatelessWidget {
  final String estado;

  const _EstadoIcon({required this.estado});

  @override
  Widget build(BuildContext context) {
    switch (estado) {
      case 'aceptada':
        return const CircleAvatar(backgroundColor: Color(0xFFECFDF5), child: Icon(Icons.check, color: Color(0xFF059669)));
      case 'rechazada':
        return const CircleAvatar(backgroundColor: Color(0xFFFEF2F2), child: Icon(Icons.close, color: Color(0xFFDC2626)));
      default:
        return const CircleAvatar(backgroundColor: Color(0xFFFFFBEB), child: Icon(Icons.hourglass_empty, color: Color(0xFFB45309)));
    }
  }
}
