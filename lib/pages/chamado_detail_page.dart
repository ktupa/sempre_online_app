// lib/pages/chamado_detail_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/ixc_api_service.dart';
import '../services/auth_service.dart';

class ChamadoDetailPage extends StatefulWidget {
  final Map<String, dynamic> chamado;
  const ChamadoDetailPage({Key? key, required this.chamado}) : super(key: key);

  @override
  State<ChamadoDetailPage> createState() => _ChamadoDetailPageState();
}

class _ChamadoDetailPageState extends State<ChamadoDetailPage> {
  late final String _idChamado;
  late String _statusChamado;
  late final String _operadorId;

  final _msgCtrl = TextEditingController();
  final _picker = ImagePicker();
  File? _image;

  late Future<List<Map<String, dynamic>>> _futureMsgs;

  @override
  void initState() {
    super.initState();
    _idChamado = widget.chamado['id'].toString();
    _statusChamado =
        widget.chamado['su_status'] ?? widget.chamado['status'] ?? 'N';
    _operadorId = AuthService().clientData!['id_login'].toString();
    _loadMessages();
  }

  void _loadMessages() {
    _futureMsgs = listarMensagensChamado(_idChamado);
  }

  bool get _podeInteragir => !['S', 'C'].contains(_statusChamado);

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _image = File(picked.path));
      // TODO: chamar seu endpoint de upload de arquivos aqui
    }
  }

  Future<void> _enviarMensagem() async {
    final texto = _msgCtrl.text.trim();
    if (texto.isEmpty) return;
    try {
      await inserirMensagemChamado(
        idChamado: _idChamado,
        operadorId: _operadorId,
        mensagem: texto,
      );
      _msgCtrl.clear();
      _image = null;
      _loadMessages();
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Falha ao enviar mensagem: $e')));
    }
  }

  Future<void> _encerrarChamado() async {
    final confirma = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Encerrar atendimento'),
            content: const Text('Deseja realmente encerrar este atendimento?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Encerrar'),
              ),
            ],
          ),
    );
    if (confirma == true) {
      // envia interação final
      await inserirMensagemChamado(
        idChamado: _idChamado,
        operadorId: _operadorId,
        mensagem: 'Atendimento encerrado.',
      );
      await encerrarChamado(
        idChamado: _idChamado,
        mensagemFinal: 'Encerrando atendimento',
        idEventoStatus: '8',
      );
      setState(() => _statusChamado = 'S');
    }
  }

  Widget _buildBubble(Map<String, dynamic> msg) {
    final cs = Theme.of(context).colorScheme;
    final text = msg['mensagem'] as String;
    final date = msg['data'] as String;
    final operador = msg['operador'] as String;

    // operador == _operadorId  → cliente (“Você”), balão à direita
    final isClient = operador == _operadorId;
    final align = isClient ? Alignment.centerRight : Alignment.centerLeft;
    final bgColor = isClient ? cs.primary : cs.surfaceVariant;
    final txtColor = isClient ? cs.onPrimary : cs.onSurface;
    final label = isClient ? 'Você' : 'Atendente';

    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment:
              isClient ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold, color: txtColor),
            ),
            const SizedBox(height: 4),
            Text(text, style: TextStyle(color: txtColor)),
            const SizedBox(height: 4),
            Text(
              date,
              style: TextStyle(fontSize: 10, color: txtColor.withOpacity(0.6)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chamado['titulo'] ?? 'Atendimento'),
        backgroundColor: cs.primary,
        actions: [
          if (_podeInteragir)
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              onPressed: _encerrarChamado,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(_loadMessages);
                await _futureMsgs;
              },
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _futureMsgs,
                builder: (_, snap) {
                  if (snap.connectionState != ConnectionState.done)
                    return const Center(child: CircularProgressIndicator());
                  if (snap.hasError)
                    return Center(child: Text('Erro: ${snap.error}'));
                  final msgs = snap.data!;
                  if (msgs.isEmpty)
                    return const Center(child: Text('Nenhuma mensagem ainda.'));
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: msgs.length,
                    itemBuilder:
                        (_, i) => _buildBubble(msgs[msgs.length - 1 - i]),
                  );
                },
              ),
            ),
          ),
          if (_podeInteragir)
            SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: cs.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.image),
                      color: cs.primary,
                      onPressed: _pickImage,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _msgCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Digite sua mensagem...',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        minLines: 1,
                        maxLines: 5,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send_rounded),
                      color: cs.primary,
                      onPressed: _enviarMensagem,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }
}
