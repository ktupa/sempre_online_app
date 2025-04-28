import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/ixc_api_service.dart';

class NovoChamadoModal extends StatefulWidget {
  final String clienteId;

  const NovoChamadoModal({Key? key, required this.clienteId}) : super(key: key);

  @override
  State<NovoChamadoModal> createState() => _NovoChamadoModalState();
}

class _NovoChamadoModalState extends State<NovoChamadoModal> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _mensagemController = TextEditingController();
  bool _isLoading = false;

  void _criarChamado() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await criarChamado(
        clienteId: widget.clienteId,
        titulo: _tituloController.text.trim(),
        mensagem: _mensagemController.text.trim(),
      );
      Get.back();
      Get.snackbar(
        'Sucesso',
        'Chamado aberto com sucesso!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Falha ao criar chamado: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo Chamado'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _tituloController,
              decoration: const InputDecoration(labelText: 'Título'),
              validator:
                  (value) =>
                      value == null || value.isEmpty ? 'Digite o título' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mensagemController,
              decoration: const InputDecoration(labelText: 'Mensagem'),
              maxLines: 4,
              validator:
                  (value) =>
                      value == null || value.isEmpty
                          ? 'Digite a mensagem'
                          : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _isLoading ? null : _criarChamado,
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Enviar'),
        ),
      ],
    );
  }
}
