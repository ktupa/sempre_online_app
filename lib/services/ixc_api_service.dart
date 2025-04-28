// lib/services/ixc_api_service.dart

import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:http/http.dart' as http;
// import 'auth_service.dart';

/// ----------------- CONFIG ----------------------------------------------------
const _ixcBase = 'https://sistema.semppreonline.com.br/webservice/v1';
const _ixcProxy = 'http://localhost:3000/api'; // proxy local (Web)
const _ixcUser = '40';
const _ixcToken =
    '5d7c9d058005631703dc1ab6d6940244125c7e29a38fd0a634c2b9b5d7118e91';

/// ----------------- HEADERS ---------------------------------------------------
Map<String, String> _headers() {
  final basic = base64Encode(utf8.encode('$_ixcUser:$_ixcToken'));
  return {
    'Content-Type': 'application/json',
    'Authorization': 'Basic $basic',
    'ixcsoft': 'listar',
  };
}

/// ----------------- GENÉRICO POST --------------------------------------------
Future<Map<String, dynamic>> _post(
  String endpoint,
  Map<String, dynamic> body,
) async {
  final base = kIsWeb ? _ixcProxy : _ixcBase;
  final url = Uri.parse('$base/$endpoint');
  final bodyJson = jsonEncode(body);

  log(
    '🔸 IXC REQUEST\n→ $url\n→ HEADERS ${jsonEncode(_headers())}\n→ BODY $bodyJson',
    name: 'IXC',
  );

  final res = await http.post(url, headers: _headers(), body: bodyJson);

  log(
    '🔹 IXC RESPONSE\n← STATUS ${res.statusCode}\n← BODY ${res.body}',
    name: 'IXC',
  );

  if (res.statusCode != 200) {
    throw Exception('IXC ${res.statusCode}: ${res.body}');
  }
  return jsonDecode(res.body) as Map<String, dynamic>;
}

/// ----------------- CONSULTA CPF ---------------------------------------------
Future<List<dynamic>> _buscarRegistrosCpf(String cpfQuery) async {
  final payload = {
    "qtype": "cliente.cnpj_cpf",
    "query": cpfQuery,
    "oper": "=",
    "page": "1",
    "rp": "20",
    "sortname": "cliente.cnpj_cpf",
    "sortorder": "desc",
  };
  final data = await _post('cliente', payload);
  return (data['registros'] as List?) ?? [];
}

/// true/false se CPF existe
Future<bool> autenticarClientePorCpf(String cpf) async {
  final limpo = cpf.replaceAll(RegExp(r'\D'), '');
  var regs = await _buscarRegistrosCpf(limpo);
  if (regs.isNotEmpty) return true;

  final formatado = _formatCpf(limpo);
  if (formatado != limpo) regs = await _buscarRegistrosCpf(formatado);
  return regs.isNotEmpty;
}

/// retorna primeiro registro ou null
Future<Map<String, dynamic>?> buscarClientePorCpf(String cpf) async {
  final limpo = cpf.replaceAll(RegExp(r'\D'), '');
  var regs = await _buscarRegistrosCpf(limpo);
  if (regs.isEmpty) {
    final fmt = _formatCpf(limpo);
    if (fmt != limpo) regs = await _buscarRegistrosCpf(fmt);
  }
  return regs.isNotEmpty ? regs.first as Map<String, dynamic> : null;
}

/// ----------------- LISTAR RADUSUÁRIOS POR CPF ------------------------------
Future<List<Map<String, dynamic>>> listarRadUsuariosPorCpf(String cpf) async {
  final limpa = cpf.replaceAll(RegExp(r'\D'), '');
  final body = {
    "qtype": "radusuarios.username",
    "query": limpa,
    "oper": "=",
    "page": "1",
    "rp": "20",
    "sortname": "radusuarios.id",
    "sortorder": "desc",
  };
  final data = await _post('radusuarios', body);
  final regs = data['registros'];
  return (regs is List)
      ? regs.cast<Map<String, dynamic>>()
      : <Map<String, dynamic>>[];
}

/// ----------------- LISTAR CONTRATOS DO CLIENTE ----------------------------
Future<List<Map<String, dynamic>>> listarContratosDoCliente(
  String idCliente,
) async {
  final body = {
    "qtype": "cliente_contrato.id_cliente",
    "query": idCliente,
    "oper": "=",
    "page": "1",
    "rp": "20",
    "sortname": "cliente_contrato.id",
    "sortorder": "desc",
  };
  final data = await _post('cliente_contrato', body);
  final regs = data['registros'];
  return (regs is List)
      ? List<Map<String, dynamic>>.from(regs)
      : <Map<String, dynamic>>[];
}

/// ----------------- HELPER ---------------------------------------------------
String _formatCpf(String digitsOnly) {
  final d = digitsOnly.padLeft(11, '0');
  return '${d.substring(0, 3)}.${d.substring(3, 6)}.${d.substring(6, 9)}-'
      '${d.substring(9)}';
}

/// ----------------- LISTAR RADUSUARIOS POR CONTRATO ------------------------
Future<List<Map<String, dynamic>>> listarRadUsuariosPorContrato(
  String idContrato,
) async {
  final body = {
    "qtype": "radusuarios.id_contrato",
    "query": idContrato,
    "oper": "=",
    "page": "1",
    "rp": "50",
    "sortname": "radusuarios.id",
    "sortorder": "desc",
  };
  final data = await _post('radusuarios', body);
  final regs = data['registros'];
  return (regs is List)
      ? List<Map<String, dynamic>>.from(regs)
      : <Map<String, dynamic>>[];
}

/// ----------------- AGREGADO: contratos + radusuarios ----------------------
Future<List<Map<String, dynamic>>> fetchContratosComRad(
  String clienteId,
) async {
  final contratos = await listarContratosDoCliente(clienteId);
  final List<Map<String, dynamic>> lista = [];
  for (final c in contratos) {
    final idC = c['id']?.toString() ?? '';
    final rads = await listarRadUsuariosPorContrato(idC);
    lista.add({'contrato': c, 'radusuarios': rads});
  }
  return lista;
}

/// Lista os serviços / descontos do contrato (TV Watch, etc)
Future<List<Map<String, dynamic>>> listarDescServDoContrato(
  String contratoId,
) async {
  final body = {
    "qtype": "cliente_contrato_desc_serv.id_contrato",
    "query": contratoId,
    "oper": "=",
    "page": "1",
    "rp": "20",
    "sortname": "cliente_contrato_desc_serv.id",
    "sortorder": "desc",
  };
  final data = await _post('cliente_contrato_desc_serv', body);
  final regs = data['registros'];
  return (regs is List)
      ? regs.cast<Map<String, dynamic>>()
      : <Map<String, dynamic>>[];
}

/// ---------- LISTAR SERVIÇOS EXTRAS (DESC/SERV) DO CONTRATO ------------
Future<List<Map<String, dynamic>>> listarServicosAdicionaisPorContrato(
  String idContrato,
) async {
  final body = {
    "qtype": "tv_usuarios.id_contrato",
    "query": idContrato,
    "oper": "=",
    "page": "1",
    "rp": "1000",
    "sortname": "tv_usuarios.id",
    "sortorder": "desc",
  };
  final data = await _post('tv_usuarios.id_contrato', body);
  final regs = data['registros'];
  return (regs is List)
      ? regs.cast<Map<String, dynamic>>()
      : <Map<String, dynamic>>[];
}
// lib/services/ixc_api_service.dart

/// ----------------- LISTAR FATURAS DO CLIENTE ----------------------------
/// Busca faturas do cliente no IXC (endpoint fn_areceber)
Future<List<Map<String, dynamic>>> listarFaturasDoCliente(
  String clienteId,
) async {
  final body = {
    "qtype": "fn_areceber.id_cliente",
    "query": clienteId,
    "oper": "=",
    "page": "1",
    "rp": "1000",
    "sortname": "fn_areceber.data_vencimento",
    "sortorder": "asc",
  };

  final data = await _post('fn_areceber', body);
  final registros = data['registros'];

  if (registros is List) {
    return List<Map<String, dynamic>>.from(registros);
  }

  return [];
}

/// ----------------- OBTER INFORMAÇÕES DE PIX ----------------------------
/// Busca QRCode e Código "Copia e Cola" da fatura
Future<Map<String, String>> getPixInfo(String idAReceber) async {
  final body = {"id_areceber": idAReceber};

  final response = await _post('get_pix', body);

  if (response['type'] != 'success') {
    throw Exception(
      response['message'] ??
          'Falha ao obter informações do Pix para a fatura $idAReceber',
    );
  }

  final qrCodeData = response['pix']?['qrCode'];

  if (qrCodeData == null) {
    throw Exception('QR Code não disponível para a fatura $idAReceber');
  }

  return {
    'qrcode': qrCodeData['qrcode']?.toString() ?? '',
    'imagemQrcode': qrCodeData['imagemQrcode']?.toString() ?? '',
  };
}

/// ----------------- DESBLOQUEAR CONFIANÇA ----------------------------
/// Libera cliente travado (ex: inadimplência, bloqueio de serviço)
Future<void> desbloquearConfianca(String idCliente) async {
  await _post('desbloqueio_confianca', {"id": idCliente});
}

/// Lista os serviços extras (TV Watch) do contrato
Future<List<Map<String, dynamic>>> listarServicosExtrasPorContrato(
  String idContrato,
) async {
  final body = {
    "qtype": "tv_usuarios.id_contrato",
    "query": idContrato,
    "oper": "=",
    "page": "1",
    "rp": "1000",
    "sortname": "tv_usuarios.id",
    "sortorder": "desc",
  };
  final data = await _post('tv_usuarios', body);
  final registros = data['registros'];
  return (registros is List)
      ? List<Map<String, dynamic>>.from(registros)
      : <Map<String, dynamic>>[];
}

Future<List<Map<String, dynamic>>> listarPerfisTvContrato(
  String contratoId,
) async {
  final body = {
    "qtype": "tv_usuarios.id_contrato",
    "query": contratoId,
    "oper": "=",
    "page": "1",
    "rp": "1000",
    "sortname": "tv_usuarios.id",
    "sortorder": "desc",
  };
  final data = await _post('tv_usuarios', body);
  final regs = data['registros'];
  return (regs is List) ? List<Map<String, dynamic>>.from(regs) : [];
}

/// Busca consumo real (upload/download) do contrato no IXC
Future<Map<String, double>> buscarConsumoRealPorContrato(
  String contratoId,
) async {
  final body = {
    "qtype": "radusuarios.id_contrato",
    "query": contratoId,
    "oper": "=",
    "page": "1",
    "rp": "20",
    "sortname": "radusuarios.id",
    "sortorder": "desc",
  };

  final data = await _post('radusuarios', body);

  final registros = data['registros'];

  if (registros is List && registros.isNotEmpty) {
    final registro = registros.first as Map<String, dynamic>;
    final uploadBytes =
        double.tryParse(registro['upload_atual']?.toString() ?? '0') ?? 0;
    final downloadBytes =
        double.tryParse(registro['download_atual']?.toString() ?? '0') ?? 0;

    // Converte para GB
    final uploadGB = uploadBytes / (1024 * 1024 * 1024);
    final downloadGB = downloadBytes / (1024 * 1024 * 1024);

    return {'upload': uploadGB, 'download': downloadGB};
  } else {
    throw Exception(
      'Nenhum registro de consumo encontrado para o contrato $contratoId',
    );
  }
}

/// Atualiza cliente no IXC
Future<void> atualizarCliente(
  String idCliente, {
  required String telefoneCelular,
  required String whatsapp,
}) async {
  final body = {"telefone_celular": telefoneCelular, "whatsapp": whatsapp};

  await _post('cliente/$idCliente', body);
}

// /// Método PUT genérico
// Future<void> _put(String endpoint, Map<String, dynamic> body) async {
//   final base = kIsWeb ? _ixcProxy : _ixcBase;
//   final url = Uri.parse('$base/$endpoint');

//   final res = await http.put(url, headers: _headers(), body: jsonEncode(body));

//   if (res.statusCode != 200) {
//     throw Exception('Erro ao atualizar: ${res.statusCode} ${res.body}');
//   }
// }

/// Busca todos os dados de cliente pelo ID
Future<Map<String, dynamic>?> buscarDadosClientePorId(String idCliente) async {
  final body = {
    "qtype": "cliente.id",
    "query": idCliente,
    "oper": "=",
    "page": "1",
    "rp": "1",
    "sortname": "cliente.id",
    "sortorder": "desc",
  };

  final data = await _post('cliente', body);
  final registros = data['registros'];

  if (registros is List && registros.isNotEmpty) {
    return Map<String, dynamic>.from(registros.first);
  }

  return null;
}

Future<List<Map<String, dynamic>>> listarChamadosCliente(
  String idCliente,
) async {
  final body = {
    "qtype": "su_ticket.id_cliente",
    "query": idCliente,
    "oper": "=",
    "page": "1",
    "rp": "100",
    "sortname": "su_ticket.id",
    "sortorder": "desc",
  };

  final data = await _post('su_ticket', body);
  final registros = data['registros'];
  return (registros is List)
      ? List<Map<String, dynamic>>.from(registros)
      : <Map<String, dynamic>>[];
}

Future<List<Map<String, dynamic>>> listarOrdensServicoCliente(
  String idCliente,
) async {
  final body = {
    "qtype": "su_oss_chamado.id_cliente",
    "query": idCliente,
    "oper": "=",
    "page": "1",
    "rp": "100",
    "sortname": "su_oss_chamado.id",
    "sortorder": "desc",
  };

  final data = await _post('su_oss_chamado', body);
  final registros = data['registros'];
  return (registros is List)
      ? List<Map<String, dynamic>>.from(registros)
      : <Map<String, dynamic>>[];
}

Future<void> responderChamadoCliente({
  required String idChamado,
  required String tokenChamado,
  required String mensagem,
}) async {
  final body = {
    "id_resposta": idChamado, // ID do chamado principal
    "menssagem": mensagem,
    "token": tokenChamado, // Token do chamado para garantir
    "status": "T", // Continua como 'T' (Tramitando)
    "interacao_pendente": "N", // Marca como interação nova do cliente
    "su_status": "N",
  };

  final data = await _post('su_ticket', body);

  if (data['type'] != 'success') {
    throw Exception('Erro ao enviar resposta: ${data['message']}');
  }
}

/// Cria um novo chamado
Future<void> criarChamado({
  required String clienteId,
  required String titulo,
  required String mensagem,
}) async {
  final payload = {
    "tipo": "C",
    "id_cliente": clienteId,
    "titulo": titulo,
    "menssagem": mensagem,
    "status": "A",
    "interacao_pendente": "I",
    "su_status": "N",
    "ixcsoft": "inserir",
  };
  await _post('su_ticket', payload);
}

/// Responde um chamado existente
Future<void> responderChamado({
  required String idChamado,
  required String tokenChamado,
  required String mensagem,
}) async {
  final payload = {
    "id_ticket": idChamado,
    "token": tokenChamado,
    "mensagem": mensagem,
    "ixcsoft": "responder",
  };
  await _post('su_ticket_resposta', payload);
}
