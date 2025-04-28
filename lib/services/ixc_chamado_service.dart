// lib/services/ixc_chamado_service.dart

import 'package:dio/dio.dart';
import 'chamado_service.dart';

class IxcChamadoService implements ChamadoService {
  final Dio _dio;

  IxcChamadoService(String baseUrl, String token)
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

  @override
  Future<List<Chamado>> fetchChamados() async {
    final resp = await _dio.get('/chamados');
    return (resp.data as List)
        .map(
          (json) => Chamado(
            id: json['id'] as int,
            assunto: json['assunto'] as String,
            status: json['status'] as String,
            data: json['data_abertura'] as String,
            ultimoSnippet: json['ultimo_texto'] as String? ?? '',
          ),
        )
        .toList();
  }

  @override
  Future<List<Mensagem>> fetchMensagens(int chamadoId) async {
    final resp = await _dio.get('/chamados/$chamadoId/mensagens');
    return (resp.data as List)
        .map(
          (json) => Mensagem(
            fromMe: (json['autor'] as String) == 'cliente',
            text: json['mensagem'] as String,
            time: DateTime.parse(json['data_hora'] as String),
          ),
        )
        .toList();
  }

  @override
  Future<void> createChamado({
    required String assunto,
    required String descricao,
    required String categoria,
  }) {
    return _dio.post(
      '/chamados',
      data: {
        'assunto': assunto,
        'descricao': descricao,
        'categoria': categoria,
      },
    );
  }

  @override
  Future<void> sendMensagem({
    required int chamadoId,
    required String mensagem,
  }) {
    return _dio.post(
      '/chamados/$chamadoId/mensagens',
      data: {'mensagem': mensagem},
    );
  }
}
