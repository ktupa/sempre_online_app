// DTOs e interface de serviço de Chamados

class Chamado {
  final int id;
  final String assunto;
  final String status;
  final String data;
  final String ultimoSnippet;

  Chamado({
    required this.id,
    required this.assunto,
    required this.status,
    required this.data,
    required this.ultimoSnippet,
  });
}

class Mensagem {
  final bool fromMe;
  final String text;
  final DateTime time;

  Mensagem({required this.fromMe, required this.text, required this.time});
}

/// Interface para abstrair o backend (mock ou IXC real)
abstract class ChamadoService {
  Future<List<Chamado>> fetchChamados();
  Future<List<Mensagem>> fetchMensagens(int chamadoId);
  Future<void> createChamado({
    required String assunto,
    required String descricao,
    required String categoria,
  });
  Future<void> sendMensagem({required int chamadoId, required String mensagem});
}
