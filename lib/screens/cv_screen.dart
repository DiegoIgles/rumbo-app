import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cv_review.dart';
import '../services/api_client.dart';
import '../services/auth_controller.dart';
import '../theme.dart';
import '../widgets/feedback_view.dart';

class CvScreen extends StatefulWidget {
  const CvScreen({super.key});

  @override
  State<CvScreen> createState() => _CvScreenState();
}

class _CvScreenState extends State<CvScreen> {
  final _textoCtrl = TextEditingController();
  String _modo = 'tradicional';
  String _entrada = 'texto'; // 'texto' | 'archivo'
  PlatformFile? _archivo;
  bool _enviando = false;
  String? _error;
  CvReview? _resultado;

  @override
  void dispose() {
    _textoCtrl.dispose();
    super.dispose();
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
    final api = context.read<AuthController>().api;

    if (_entrada == 'archivo') {
      final archivo = _archivo;
      if (archivo == null) {
        setState(() => _error = 'Elegí un archivo PDF o Word (.docx)');
        return;
      }
      setState(() {
        _enviando = true;
        _error = null;
      });
      try {
        final review = await api.reviewCvArchivo(
          modo: _modo,
          nombreArchivo: archivo.name,
          rutaArchivo: archivo.path,
          bytes: archivo.bytes,
        );
        setState(() => _resultado = review);
      } on ApiException catch (e) {
        setState(() => _error = e.message);
      } catch (_) {
        setState(() => _error = 'No se pudo revisar tu CV');
      } finally {
        if (mounted) setState(() => _enviando = false);
      }
      return;
    }

    if (_textoCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Pegá el texto de tu CV o pitch');
      return;
    }
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      final review = await api.reviewCv(modo: _modo, texto: _textoCtrl.text.trim());
      setState(() => _resultado = review);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'No se pudo revisar tu CV');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Revisión de CV con IA')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'tradicional', label: Text('CV tradicional')),
                  ButtonSegment(value: 'freelance', label: Text('Pitch freelance')),
                ],
                selected: {_modo},
                onSelectionChanged: (s) => setState(() => _modo = s.first),
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'texto', icon: Icon(Icons.edit_note), label: Text('Pegar texto')),
                  ButtonSegment(value: 'archivo', icon: Icon(Icons.upload_file), label: Text('Subir archivo')),
                ],
                selected: {_entrada},
                onSelectionChanged: (s) => setState(() {
                  _entrada = s.first;
                  _error = null;
                }),
              ),
              const SizedBox(height: 16),
              if (_entrada == 'texto')
                TextField(
                  controller: _textoCtrl,
                  maxLines: 10,
                  decoration: InputDecoration(
                    labelText: _modo == 'tradicional' ? 'Pegá el texto de tu CV' : 'Pegá tu pitch / descripción de servicios',
                    alignLabelWithHint: true,
                  ),
                )
              else
                _buildSelectorArchivo(context),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Color(0xFFDC2626))),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _enviando ? null : _enviar,
                  child: _enviando
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Recibir feedback'),
                ),
              ),
              if (_resultado != null) ...[
                const SizedBox(height: 28),
                FeedbackView(feedback: _resultado!.feedback),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectorArchivo(BuildContext context) {
    final archivo = _archivo;
    if (archivo == null) {
      return OutlinedButton.icon(
        onPressed: _elegirArchivo,
        icon: const Icon(Icons.upload_file),
        label: const Text('Elegir archivo (.pdf o .docx)'),
      );
    }
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: rumboPrimary.withValues(alpha: 0.12),
          child: Icon(
            archivo.extension == 'pdf' ? Icons.picture_as_pdf_outlined : Icons.description_outlined,
            color: rumboPrimary,
          ),
        ),
        title: Text(archivo.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${(archivo.size / 1024).toStringAsFixed(0)} KB'),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => setState(() => _archivo = null),
        ),
      ),
    );
  }
}
