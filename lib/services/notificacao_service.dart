// lib/services/notificacao_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _backendUrl =
    kIsWeb
        ? 'http://localhost:8087/notificacoes'
        : 'http://127.0.0.1:8087/notificacoes'; // ajuste para sua VPS real

/// Busca todas as notificações do backend por cliente/contrato
Future<List<Map<String, dynamic>>> buscarNotificacoesDoCliente({
  required String idCliente,
  String? idContrato,
}) async {
  final res = await http.get(Uri.parse(_backendUrl));
  if (res.statusCode != 200) throw Exception('Erro ao buscar notificações');

  final todas =
      (jsonDecode(res.body) as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

  final prefs = await SharedPreferences.getInstance();
  final idsRemovidas = prefs.getStringList('notificacoes_ocultadas') ?? [];

  return todas.where((n) {
    return n['id_cliente'] == idCliente &&
        (idContrato == null || n['id_contrato'] == idContrato) &&
        !idsRemovidas.contains(n['id'].toString());
  }).toList();
}

/// Oculta permanentemente uma notificação
Future<void> ocultarNotificacao(int id) async {
  final prefs = await SharedPreferences.getInstance();
  final atuais = prefs.getStringList('notificacoes_ocultadas') ?? [];
  if (!atuais.contains(id.toString())) {
    atuais.add(id.toString());
    await prefs.setStringList('notificacoes_ocultadas', atuais);
  }
}
