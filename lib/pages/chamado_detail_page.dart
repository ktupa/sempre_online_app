import 'package:flutter/material.dart';

class ChamadoDetailPage extends StatelessWidget {
  final Map<String, dynamic> chamado;

  const ChamadoDetailPage({Key? key, required this.chamado}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.primary,
        title: Text(
          'Chamado #${chamado['id']}',
          style: TextStyle(color: cs.onPrimary),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _buildInfo('Assunto', chamado['titulo']),
            _buildInfo('Status', chamado['status']),
            _buildInfo('Data Abertura', chamado['data_criacao']),
            _buildInfo('Prioridade', chamado['prioridade']),
            _buildInfo('Origem', chamado['origem_endereco']),
            _buildInfo('Mensagem', chamado['menssagem']),
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
