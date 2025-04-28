import 'dart:async';
import 'chamado_service.dart';

class MockChamadoService implements ChamadoService {
  final List<Chamado> _lista = [
    Chamado(
      id: 101,
      assunto: 'Internet Lenta',
      status: 'Aberto',
      data: '25/04/2025',
      ultimoSnippet: 'Ainda está lento...',
    ),
    Chamado(
      id: 102,
      assunto: '2ª Via de Boleto',
      status: 'Em Atendimento',
      data: '24/04/2025',
      ultimoSnippet: 'Preciso do boleto...',
    ),
    Chamado(
      id: 103,
      assunto: 'Sem Conexão',
      status: 'Finalizado',
      data: '20/04/2025',
      ultimoSnippet: 'Problema resolvido ontem.',
    ),
  ];

  final Map<int, List<Mensagem>> _mensagens = {
    101: [
      Mensagem(
        fromMe: true,
        text: 'Olá, requero suporte urgente.',
        time: DateTime(2025, 4, 25, 9, 30),
      ),
      Mensagem(
        fromMe: false,
        text: 'Olá! Estamos verificando.',
        time: DateTime(2025, 4, 25, 10, 0),
      ),
    ],
    102: [
      Mensagem(
        fromMe: true,
        text: 'Preciso da segunda via do boleto.',
        time: DateTime(2025, 4, 24, 8, 0),
      ),
    ],
    103: [
      Mensagem(
        fromMe: false,
        text: 'Chamado encerrado com sucesso.',
        time: DateTime(2025, 4, 20, 15, 0),
      ),
    ],
  };

  @override
  Future<List<Chamado>> fetchChamados() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_lista);
  }

  @override
  Future<List<Mensagem>> fetchMensagens(int chamadoId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_mensagens[chamadoId] ?? []);
  }

  @override
  Future<void> createChamado({
    required String assunto,
    required String descricao,
    required String categoria,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newId =
        (_lista.map((c) => c.id).fold(0, (p, id) => id > p ? id : p)) + 1;
    _lista.insert(
      0,
      Chamado(
        id: newId,
        assunto: assunto,
        status: 'Aberto',
        data: '26/04/2025',
        ultimoSnippet: descricao,
      ),
    );
    _mensagens[newId] = [
      Mensagem(fromMe: true, text: descricao, time: DateTime.now()),
    ];
  }

  @override
  Future<void> sendMensagem({
    required int chamadoId,
    required String mensagem,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _mensagens[chamadoId]?.add(
      Mensagem(fromMe: true, text: mensagem, time: DateTime.now()),
    );
  }
}
