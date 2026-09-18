import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cv_review.dart';
import '../services/api_client.dart';
import '../services/auth_controller.dart';
import '../theme.dart';
import '../widgets/feedback_view.dart';
import '../widgets/ui_kit.dart';

class CvScreen extends StatefulWidget {
  const CvScreen({super.key});

  @override
  State<CvScreen> createState() => _CvScreenState();
}

class _CvScreenState extends State<CvScreen> {
  final _textoCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String _modo = 'tradicional';
  String _entrada = 'texto'; // 'texto' | 'archivo'
  PlatformFile? _archivo;
  bool _enviando = false;
  String? _error;
  CvReview? _resultado;

  @override
  void initState() {
    super.initState();
    _textoCtrl.addListener(_onTextoCambio);
  }

  @override
  void dispose() {
    _textoCtrl.removeListener(_onTextoCambio);
    _textoCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onTextoCambio() {
    // Solo para refrescar el contador de caracteres.
    if (mounted) setState(() {});
  }

  Future<void> _elegirArchivo() async {
    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx'],
      withData: false,
    );
    if (resultado == null || resultado.files.isEmpty) return;
    setState(() {
      _archivo = resultado.files.single;
      _error = null;
    });
  }

  Future<void> _enviar() async {
    FocusScope.of(context).unfocus();
    final api = context.read<AuthController>().api;

    if (_entrada == 'archivo' && _archivo == null) {
      setState(() => _error = 'Elegí un archivo PDF o Word (.docx)');
      return;
    }
    if (_entrada == 'texto' && _textoCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Pegá el texto de tu CV o pitch');
      return;
    }

    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      final review = _entrada == 'archivo'
          ? await api.reviewCvArchivo(
              modo: _modo,
              nombreArchivo: _archivo!.name,
              rutaArchivo: _archivo!.path,
              bytes: _archivo!.bytes,
            )
          : await api.reviewCv(modo: _modo, texto: _textoCtrl.text.trim());
      if (!mounted) return;
      setState(() => _resultado = review);
      // Lleva la vista al feedback: si no, el resultado queda fuera de pantalla
      // debajo del formulario y parece que no pasó nada.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: RumboMotion.slow,
            curve: RumboMotion.decelerate,
          );
        }
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo revisar tu CV');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esTradicional = _modo == 'tradicional';
    return Scaffold(
      appBar: AppBar(title: const Text('Revisión con IA')),
      body: SafeArea(
        top: false,
        child: ListView(
          controller: _scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            FadeSlideIn(
              index: 0,
              child: BrandHeader(
                icono: Icons.auto_awesome,
                titulo: esTradicional ? 'Tu CV, revisado' : 'Tu pitch, revisado',
                subtitulo: esTradicional
                    ? 'Pegá o subí tu CV y recibí fortalezas y puntos a mejorar.'
                    : 'Contá cómo ofrecés tus servicios y afinamos tu propuesta.',
              ),
            ),
            const SizedBox(height: 24),
            const FadeSlideIn(index: 1, child: SectionTitle('¿Qué querés revisar?')),
            const SizedBox(height: 12),
            FadeSlideIn(
              index: 2,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'tradicional', label: Text('CV tradicional')),
                  ButtonSegment(value: 'freelance', label: Text('Pitch freelance')),
                ],
                selected: {_modo},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _modo = s.first),
              ),
            ),
            const SizedBox(height: 22),
            const FadeSlideIn(index: 3, child: SectionTitle('¿Cómo lo mandás?')),
            const SizedBox(height: 12),
            FadeSlideIn(
              index: 4,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'texto',
                    icon: Icon(Icons.edit_note_rounded, size: 17),
                    label: Text('Pegar texto'),
                  ),
                  ButtonSegment(
                    value: 'archivo',
                    icon: Icon(Icons.upload_file_rounded, size: 17),
                    label: Text('Subir archivo'),
                  ),
                ],
                selected: {_entrada},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() {
                  _entrada = s.first;
                  _error = null;
                }),
              ),
            ),
            const SizedBox(height: 18),
            AnimatedSize(
              duration: RumboMotion.medium,
              curve: RumboMotion.emphasized,
              alignment: Alignment.topCenter,
              child: _entrada == 'texto' ? _buildCampoTexto(esTradicional) : _buildSelectorArchivo(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              InfoBanner(mensaje: _error!),
            ],
            const SizedBox(height: 22),
            LoadingButton(
              texto: 'Recibir feedback',
              textoCargando: 'La IA está leyendo...',
              cargando: _enviando,
              onPressed: _enviar,
              icono: Icons.auto_awesome,
            ),
            if (_resultado != null) ...[
              const SizedBox(height: 32),
              const SectionTitle('Resultado'),
              const SizedBox(height: 14),
              FeedbackView(feedback: _resultado!.feedback, titulo: 'Lo que notó la IA'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCampoTexto(bool esTradicional) {
    final largo = _textoCtrl.text.trim().length;
    return Column(
      key: const ValueKey('texto'),
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextField(
          controller: _textoCtrl,
          maxLines: 9,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: esTradicional
                ? 'Pegá acá el texto de tu CV: estudios, experiencia, habilidades...'
                : 'Pegá tu pitch: qué servicios ofrecés, a quién y con qué diferencial...',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          largo == 0 ? 'Sin texto todavía' : '$largo caracteres',
          style: const TextStyle(color: RumboColors.textLow, fontSize: 11.5),
        ),
      ],
    );
  }

  Widget _buildSelectorArchivo() {
    final archivo = _archivo;
    if (archivo == null) {
      return PressableScale(
        key: const ValueKey('sin-archivo'),
        onTap: _elegirArchivo,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
          decoration: BoxDecoration(
            color: RumboColors.surface,
            borderRadius: RumboRadii.card,
            border: Border.all(color: RumboColors.outline),
          ),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: RumboColors.navyBright.withValues(alpha: 0.13),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cloud_upload_outlined, color: RumboColors.navyBright, size: 25),
              ),
              const SizedBox(height: 14),
              Text('Elegir archivo', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              const Text(
                'PDF o Word (.docx)',
                style: TextStyle(color: RumboColors.textLow, fontSize: 12.5),
              ),
            ],
          ),
        ),
      );
    }

    final esPdf = archivo.extension?.toLowerCase() == 'pdf';
    return RumboCard(
      key: const ValueKey('con-archivo'),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (esPdf ? RumboColors.crimsonBright : RumboColors.navyBright).withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(RumboRadii.sm),
            ),
            child: Icon(
              esPdf ? Icons.picture_as_pdf_outlined : Icons.article_outlined,
              color: esPdf ? RumboColors.crimsonBright : RumboColors.navyBright,
              size: 21,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  archivo.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  '${(archivo.size / 1024).toStringAsFixed(0)} KB',
                  style: const TextStyle(color: RumboColors.textLow, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Quitar',
            icon: const Icon(Icons.close_rounded, size: 19),
            onPressed: () => setState(() => _archivo = null),
          ),
        ],
      ),
    );
  }
}
