import 'package:flutter/material.dart';

class OrdemServicoDetailPage extends StatelessWidget {
  final Map<String, dynamic> ordemServico;

  const OrdemServicoDetailPage({Key? key, required this.ordemServico})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.primary,
        title: Text(
          'OS #${ordemServico['id']}',
          style: TextStyle(color: cs.onPrimary),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _buildInfo('Mensagem', ordemServico['mensagem']),
            _buildInfo('Status', ordemServico['status']),
            _buildInfo('Prioridade', ordemServico['prioridade']),
            _buildInfo('Data Abertura', ordemServico['data_abertura']),
            _buildInfo('Endereço', ordemServico['endereco']),
            _buildInfo('Complemento', ordemServico['complemento']),
            _buildInfo('Referência', ordemServico['referencia']),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value?.isNotEmpty == true ? value! : '—'),
        ],
      ),
    );
  }
}
