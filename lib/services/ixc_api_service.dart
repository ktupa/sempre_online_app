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

Map<String, String> _execHeaders() {
  final basic = base64Encode(utf8.encode('$_ixcUser:$_ixcToken'));
  return {
    'Content-Type': 'application/json',
    'Authorization': 'Basic $basic',
    // pode ser 'executar' ou até mesmo omitir totalmente este campo,
    // mas vamos usar 'executar' para operações de escrita.
    'ixcsoft': 'executar',
  };
}

Future<Map<String, dynamic>> _ixcPut2(
  String endpoint,
  Map<String, dynamic> body,
) async {
  final base = kIsWeb ? _ixcProxy : _ixcBase;
  final url = Uri.parse('$base/$endpoint');
  final res = await http.put(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization':
          'Basic ${base64Encode(utf8.encode('$_ixcUser:$_ixcToken'))}',
    },
    body: jsonEncode(body),
  );
  if (res.statusCode != 200) {
    throw Exception('IXC PUT ${res.statusCode}: ${res.body}');
  }
  return jsonDecode(res.body) as Map<String, dynamic>;
}

/// Atualiza apenas a senha e o login (hotsite_email) de um cliente existente
Future<void> atualizarSenhaComTodosCampos({
  required String idCliente,
  required String novaSenha,
  required String novoLogin,
}) async {
  // 1. Buscar cliente completo
  final cliente = await buscarDadosClientePorId(idCliente);
  if (cliente == null) {
    throw Exception('Cliente não encontrado para o ID $idCliente');
  }

  // 2. Atualizar os campos desejados
  cliente['senha'] = novaSenha;
  cliente['hotsite_email'] = novoLogin;
  cliente['acesso_automatico_central'] = 'S';
  cliente['alterar_senha_primeiro_acesso'] = 'N';

  // 3. Enviar PUT com tudo preenchido
  final base = kIsWeb ? _ixcProxy : _ixcBase;
  final url = Uri.parse('$base/cliente/$idCliente');
  final res = await http.put(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization':
          'Basic ${base64Encode(utf8.encode('$_ixcUser:$_ixcToken'))}',
    },
    body: jsonEncode(cliente),
  );

  if (res.statusCode != 200) {
    throw Exception('Erro ao atualizar: ${res.statusCode}: ${res.body}');
  }

  final resJson = jsonDecode(res.body);
  if (resJson['type'] != 'success') {
    throw Exception('Falha ao atualizar senha: ${resJson['message']}');
  }
}

// 1) Novo builder de headers, controlando apenas o campo ixcsoft
Map<String, String> _ixcHeaders(String action) {
  const user = '40';
  const token =
      '5d7c9d058005631703dc1ab6d6940244125c7e29a38fd0a634c2b9b5d7118e91';
  final basic = base64Encode(utf8.encode('$user:$token'));
  return {
    'Content-Type': 'application/json',
    'Authorization': 'Basic $basic',
    'ixcsoft': action,
  };
}

// 2) Post genérico que recebe o “action” (listar, inserir…)
Future<Map<String, dynamic>> _ixcPost(
  String endpoint,
  Map<String, dynamic> body, {
  String action = 'listar',
}) async {
  final base = kIsWeb ? _ixcProxy : _ixcBase;
  final url = Uri.parse('$base/$endpoint');
  final payload = jsonEncode(body);

  log('🔸 IXC REQUEST → $endpoint ($action)\n$payload', name: 'IXC');
  final res = await http.post(url, headers: _ixcHeaders(action), body: payload);
  log('🔹 IXC RESPONSE ← ${res.statusCode}\n${res.body}', name: 'IXC');

  if (res.statusCode != 200) {
    throw Exception('IXC HTTP ${res.statusCode}: ${res.body}');
  }
  return jsonDecode(res.body) as Map<String, dynamic>;
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

/// ----------------- GENÉRICO POST PARA EXECUTAR -----------------------
Future<Map<String, dynamic>> _postExec(
  String endpoint,
  Map<String, dynamic> body,
) async {
  final base = kIsWeb ? _ixcProxy : _ixcBase;
  final url = Uri.parse('$base/$endpoint');
  final bodyJson = jsonEncode(body);

  log(
    '🔸 IXC EXEC REQUEST\n→ $url\n→ HEADERS ${jsonEncode(_execHeaders())}\n→ BODY $bodyJson',
    name: 'IXC',
  );
  final res = await http.post(url, headers: _execHeaders(), body: bodyJson);
  log(
    '🔹 IXC EXEC RESPONSE\n← STATUS ${res.statusCode}\n← BODY ${res.body}',
    name: 'IXC',
  );

  if (res.statusCode != 200) {
    throw Exception('IXC HTTP ${res.statusCode}: ${res.body}');
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

Future<bool> autenticarLoginPorHotsiteEmail({
  required String cpf,
  required String senhaDigitada,
}) async {
  final cliente = await buscarClienteConfiavel(cpf);
  if (cliente == null) return false;

  final loginReal = (cliente['hotsite_email'] ?? '').toString().replaceAll(
    RegExp(r'\D'),
    '',
  );
  final senhaReal = (cliente['senha'] ?? '').toString().trim();

  final cpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');

  if (loginReal.isEmpty || senhaReal.isEmpty) return false;
  if (loginReal != cpfLimpo) return false;
  if (senhaDigitada != senhaReal) return false;

  return true;
}

/// Busca um cliente pelo CPF (retorna **todos** os campos do registro)
Future<Map<String, dynamic>?> buscarClienteConfiavel(String cpf) async {
  final limpa = cpf.replaceAll(RegExp(r'\D'), '');
  final fmt =
      (String d) =>
          '${d.substring(0, 3)}.${d.substring(3, 6)}.'
          '${d.substring(6, 9)}-${d.substring(9)}';
  for (final q in [limpa, fmt(limpa)]) {
    final payload = {
      "qtype": "cliente.cnpj_cpf",
      "query": q,
      "oper": "=",
      "page": "1",
      "rp": "1",
      "sortname": "cliente.cnpj_cpf",
      "sortorder": "desc",
    };
    final url = Uri.parse('$_ixcBase/cliente');
    final res = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization':
            'Basic ${base64Encode(utf8.encode('$_ixcUser:$_ixcToken'))}',
        'ixcsoft': 'listar',
      },
      body: jsonEncode(payload),
    );
    if (res.statusCode != 200) continue;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final regs = data['registros'] as List? ?? [];
    if (regs.isNotEmpty) return Map<String, dynamic>.from(regs.first);
  }
  return null;
}

/// Helper para formatar CPF “12345678901” → “123.456.789-01”
String _formatCpf(String digitsOnly) {
  final d = digitsOnly.padLeft(11, '0');
  return '${d.substring(0, 3)}.${d.substring(3, 6)}.${d.substring(6, 9)}-${d.substring(9)}';
}

Future<Map<String, dynamic>?> buscarClientePorCpf2(String cpf) async {
  final limpa = cpf.replaceAll(RegExp(r'\D'), '');
  final payload = {
    "qtype": "cliente.cnpj_cpf",
    "query": limpa,
    "oper": "=",
    "page": "1",
    "rp": "1",
    "sortname": "cliente.cnpj_cpf",
    "sortorder": "desc",
  };
  final url = Uri.parse('$_ixcBase/cliente');
  final res = await http.post(
    url,
    headers: _ixcHeaders('listar'),
    body: jsonEncode(payload),
  );
  if (res.statusCode != 200) {
    throw Exception('Erro ao buscar por CPF: ${res.statusCode}');
  }
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  final regs = data['registros'] as List<dynamic>? ?? [];
  return regs.isEmpty ? null : Map<String, dynamic>.from(regs.first);
}

/// retorna primeiro registro ou null
Future<Map<String, dynamic>?> buscarClientePorCpf(String cpf) async {
  final limpo = cpf.replaceAll(RegExp(r'\D'), '');
  var regs = await _buscarRegistrosCpf(limpo);

  if (regs.isEmpty) {
    final fmt = _formatCpf(limpo);
    if (fmt != limpo) regs = await _buscarRegistrosCpf(fmt);
  }

  // Filtra só os ativos
  final ativos = regs.where((r) => r['ativo'] == 'S').toList();

  if (ativos.isEmpty) return null;

  // Retorna o primeiro ativo (ou mais antigo ou mais recente)
  ativos.sort((a, b) {
    final aData = DateTime.tryParse(a['data_cadastro'] ?? '') ?? DateTime(2000);
    final bData = DateTime.tryParse(b['data_cadastro'] ?? '') ?? DateTime(2000);
    return aData.compareTo(bData); // mais antigo
  });

  return ativos.first as Map<String, dynamic>;
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
  final base = kIsWeb ? _ixcProxy : _ixcBase;
  final url = Uri.parse('$base/desbloqueio_confianca');

  final headers = {
    'Content-Type': 'application/json',
    'Authorization':
        'Basic ${base64Encode(utf8.encode('$_ixcUser:$_ixcToken'))}',
    'ixcsoft': 'executar',
  };

  final body = jsonEncode({"id": idCliente});
  final res = await http.post(url, headers: headers, body: body);

  if (res.statusCode != 200) {
    throw Exception('Erro HTTP ${res.statusCode}: ${res.body}');
  }

  final data = jsonDecode(res.body);
  if (data['type'] != 'success') {
    final msg = data['message']?.toString() ?? 'Erro desconhecido';
    // Análise do conteúdo da mensagem
    if (msg.contains('contrato está inativo')) {
      throw Exception('Não é possível liberar confiança: contrato inativo.');
    } else if (msg.contains('já foi utilizado')) {
      throw Exception('Você já usou sua liberação de confiança.');
    } else {
      throw Exception(msg);
    }
  }
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
  final url = Uri.parse('$_ixcBase/cliente');
  final body = jsonEncode({
    "qtype": "cliente.id",
    "query": idCliente,
    "oper": "=",
    "page": "1",
    "rp": "1",
    "sortname": "cliente.id",
    "sortorder": "desc",
  });

  final res = await http.post(url, headers: _ixcHeaders('listar'), body: body);
  if (res.statusCode != 200) {
    throw Exception('Erro ao buscar cliente: ${res.statusCode} ${res.body}');
  }

  final data = jsonDecode(res.body) as Map<String, dynamic>;
  final regs = data['registros'] as List<dynamic>? ?? [];
  if (regs.isEmpty) return null;
  return Map<String, dynamic>.from(regs.first);
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

  if (registros is List) {
    return List<Map<String, dynamic>>.from(registros);
  } else if (registros is Map) {
    return registros.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  return [];
}

Future<void> enviarMensagemChamado({
  required String idChamado,
  required String tokenChamado,
  required String mensagem,
}) async {
  final payload = {
    "id_resposta": idChamado,
    "menssagem": mensagem,
    "token": tokenChamado,
    "interacao_pendente": "N",
    "status": "T",
    "su_status": "N",
  };

  final data = await _post('su_ticket', payload);
  if (data['type'] != 'success') {
    throw Exception('Erro ao enviar mensagem: ${data['message']}');
  }
}

Future<void> enviarMensagemVisitaTecnica({
  required String idChamado,
  required String mensagem,
}) async {
  final payload = {
    "id_chamado": idChamado,
    "id_evento": "8", // ou outro evento adequado
    "id_resposta": "",
    "mensagem": mensagem,
    "data_inicio": "",
    "data_final": "",
    "id_tecnico": "",
    "status": "A",
    "tipo_cobranca": "NENHUM",
    "id_evento_status": "",
    "data": "",
    "id_equipe": "",
    "id_proxima_tarefa": "",
    "finaliza_processo": "N",
    "latitude": "",
    "longitude": "",
    "gps_time": "",
  };

  final res = await _post('su_oss_chamado_mensagem', payload);

  if (res['type'] != 'success') {
    throw Exception(
      'Erro ao enviar mensagem para Visita Técnica: ${res['message']}',
    );
  }
}

Future<List<Map<String, dynamic>>> listarAssuntosChamado() async {
  final payload = {
    "qtype": "su_oss_assunto.id",
    "query": "0",
    "oper": ">",
    "page": "1",
    "rp": "100",
    "sortname": "su_oss_assunto.id",
    "sortorder": "asc",
  };

  final data = await _post('su_oss_assunto', payload);
  final registros = data['registros'];

  if (registros is List) {
    return registros
        .map((e) => Map<String, dynamic>.from(e))
        .where((a) => a['ativo'] == 'S')
        .toList();
  }

  return [];
}

/// URL base (proxy se web, senão IXC diretamente)
String get _baseUrl =>
    kIsWeb
        ? 'http://localhost:3000/api'
        : 'https://sistema.semppreonline.com.br/webservice/v1';

/// Novo builder de headers específico para operações de suporte
Map<String, String> _supportHeaders([String ixcs = 'listar']) {
  const user = '40';
  const token =
      '5d7c9d058005631703dc1ab6d6940244125c7e29a38fd0a634c2b9b5d7118e91';
  final basic = base64Encode(utf8.encode('$user:$token'));
  return {
    'Content-Type': 'application/json',
    'Authorization': 'Basic $basic',
    'ixcsoft': ixcs,
  };
}

/// ----------------- INSERIR CHAMADO ----------------------------
Future<Map<String, dynamic>> inserirTicket(Map<String, dynamic> payload) async {
  final url = Uri.parse('$_baseUrl/su_ticket');
  log('🔸 INSERIR su_ticket → $payload', name: 'IXC');
  final res = await http.post(
    url,
    headers: _supportHeaders('inserir'),
    body: jsonEncode(payload),
  );
  log('🔹 STATUS ${res.statusCode}\n${res.body}', name: 'IXC');
  if (res.statusCode != 200) {
    throw Exception('Erro ao inserir chamado: ${res.statusCode}');
  }
  return jsonDecode(res.body) as Map<String, dynamic>;
}

/// ----------------- LISTAR CHAMADOS ----------------------------
Future<List<Map<String, dynamic>>> listarTickets({
  required String qtype,
  required String query,
  String oper = '=',
  int page = 1,
  int rp = 100,
  String sortname = 'su_ticket.id',
  String sortorder = 'desc',
}) async {
  final url = Uri.parse('$_baseUrl/su_ticket');
  final body = {
    'qtype': qtype,
    'query': query,
    'oper': oper,
    'page': page.toString(),
    'rp': rp.toString(),
    'sortname': sortname,
    'sortorder': sortorder,
  };
  log('🔸 LISTAR su_ticket → $body', name: 'IXC');
  final res = await http.post(
    url,
    headers: _supportHeaders('listar'),
    body: jsonEncode(body),
  );
  log('🔹 STATUS ${res.statusCode}\n${res.body}', name: 'IXC');
  if (res.statusCode != 200) {
    throw Exception('Erro ao listar chamados: ${res.statusCode}');
  }
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  final regs = data['registros'] as List<dynamic>? ?? [];
  return regs.map((e) => Map<String, dynamic>.from(e)).toList();
}

/// ----------------- EDITAR CHAMADO ----------------------------
Future<Map<String, dynamic>> editarTicket(
  String id,
  Map<String, dynamic> payload,
) async {
  final url = Uri.parse('$_baseUrl/su_ticket/$id');
  log('🔸 EDITAR su_ticket/$id → $payload', name: 'IXC');
  final res = await http.put(
    url,
    headers: _supportHeaders(), // PUT normalmente não muda ixcsoft
    body: jsonEncode(payload),
  );
  log('🔹 STATUS ${res.statusCode}\n${res.body}', name: 'IXC');
  if (res.statusCode != 200) {
    throw Exception('Erro ao editar chamado: ${res.statusCode}');
  }
  return jsonDecode(res.body) as Map<String, dynamic>;
}

/// ----------------- DELETAR CHAMADO ----------------------------
Future<void> deletarTicket(String id) async {
  final url = Uri.parse('$_baseUrl/su_ticket/$id');
  log('🔸 DELETAR su_ticket/$id', name: 'IXC');
  final res = await http.delete(url, headers: _supportHeaders());
  log('🔹 STATUS ${res.statusCode}\n${res.body}', name: 'IXC');
  if (res.statusCode != 200) {
    throw Exception('Erro ao deletar chamado: ${res.statusCode}');
  }
}

/// ----------------- FINALIZAR CHAMADO ----------------------------
Future<void> finalizarChamado(String idChamado) async {
  final url = Uri.parse('$_baseUrl/su_ticket');
  final body = {"id": idChamado, "su_status": "S", "status": "F"};
  log('🔸 FINALIZAR su_ticket → $body', name: 'IXC');
  final res = await http.post(
    url,
    headers: _supportHeaders('inserir'),
    body: jsonEncode(body),
  );
  log('🔹 STATUS ${res.statusCode}\n${res.body}', name: 'IXC');
  if (res.statusCode != 200) {
    throw Exception('Erro ao finalizar chamado: ${res.statusCode}');
  }
}

// 1) Nova fábrica de headers para operações de escrita (inserir, editar, etc)
Map<String, String> _headersIncluir() {
  final basic = base64Encode(utf8.encode('$_ixcUser:$_ixcToken'));
  return {
    'Content-Type': 'application/json',
    'Authorization': 'Basic $basic',
    'ixcsoft': 'inserir', // → override para inserções
  };
}

// 2) Método genérico _post_ para leitura (“listar”)
Future<Map<String, dynamic>> _postListar(
  String endpoint,
  Map<String, dynamic> body,
) async {
  final url = Uri.parse('${kIsWeb ? _ixcProxy : _ixcBase}/$endpoint');
  final res = await http.post(url, headers: _headers(), body: jsonEncode(body));
  if (res.statusCode != 200) {
    throw Exception('IXC listar ${res.statusCode}: ${res.body}');
  }
  return jsonDecode(res.body) as Map<String, dynamic>;
}

// 3) Novo método genérico _post_ para escrita (“inserir”)
Future<Map<String, dynamic>> _postIncluir(
  String endpoint,
  Map<String, dynamic> body,
) async {
  final url = Uri.parse('${kIsWeb ? _ixcProxy : _ixcBase}/$endpoint');
  log('🔸 INC-REQUEST $url → ${jsonEncode(body)}', name: 'IXC');
  final res = await http.post(
    url,
    headers: _headersIncluir(),
    body: jsonEncode(body),
  );
  log('🔹 INC-RESPONSE ← ${res.statusCode} ${res.body}', name: 'IXC');
  if (res.statusCode != 200) {
    throw Exception('IXC inserir ${res.statusCode}: ${res.body}');
  }
  return jsonDecode(res.body) as Map<String, dynamic>;
}

// 4) Cria um chamado simples
Future<void> criarChamado({
  required String clienteId,
  required String titulo,
  required String mensagem,
}) async {
  final payload = {
    'tipo': 'C',
    'id_cliente': clienteId,
    'titulo': titulo,
    'menssagem': mensagem,
    'status': 'A',
    'interacao_pendente': 'I',
    'su_status': 'N',
    'ixcsoft': 'inserir', // redundante, mas seguro
  };
  final res = await _postIncluir('su_ticket', payload);
  if (res['type'] != 'success') {
    throw Exception('Falha ao criar chamado: ${res['message']}');
  }
}

// 5) Cria um chamado “avançado”, incluindo assunto, setor, etc
Future<void> criarChamadoAvancado({
  required String clienteId,
  required String titulo,
  required String mensagem,
  required String idAssunto,
  required String idDepartamento,
  required String origemEndereco,
  required String prioridade,
  required String idLogin,
  required String idContrato,
}) async {
  final payload = {
    'tipo': 'C',
    'id_cliente': clienteId,
    'titulo': titulo,
    'menssagem': mensagem,
    'id_assunto': idAssunto,
    'descricao_assunto': titulo,
    'id_ticket_setor': idDepartamento,
    'origem_endereco': origemEndereco,
    'prioridade': prioridade,
    'id_login': idLogin,
    'id_contrato': idContrato,
    'status': 'A',
    'interacao_pendente': 'I',
    'su_status': 'N',
    'ixcsoft': 'inserir',
  };
  log('📨 Criando CHAMADO AVANÇADO → $payload', name: 'IXC');
  final res = await _postIncluir('su_ticket', payload);
  log('📩 Resposta CHAMADO AVANÇADO ← $res', name: 'IXC');
  if (res['type'] != 'success') {
    throw Exception('Falha ao criar chamado: ${res['message'] ?? 'erro IXC'}');
  }
}

// 8) Lista mensagens de um chamado (já usava _postListar)
Future<List<Map<String, dynamic>>> listarMensagensChamado(
  String idChamado,
) async {
  final data = await _ixcPost('su_mensagens', {
    'qtype': 'su_mensagens.id_ticket',
    'query': idChamado,
    'oper': '=',
    'page': '1',
    'rp': '1000',
    'sortname': 'su_mensagens.id',
    'sortorder': 'asc',
  }, action: 'listar');

  final regs = data['registros'] as List? ?? [];
  return regs
      .map(
        (r) => {
          'mensagem': r['mensagem'] ?? r['menssagem'] ?? '',
          'data': r['data'] ?? '',
          'operador': r['operador']?.toString() ?? '',
        },
      )
      .toList();
}

// 4) Inserir mensagem de Atendimento (su_mensagens / inserir)
Future<void> inserirMensagemChamado({
  required String idChamado,
  required String operadorId,
  required String mensagem,
}) async {
  final payload = {
    'id_ticket': idChamado,
    'operador': operadorId,
    'mensagem': mensagem,
    'visibilidade_mensagens': 'PU', // público
  };

  final res = await _ixcPost('su_mensagens', payload, action: 'inserir');
  if (res['type'] != 'success') {
    throw Exception('Falha ao inserir mensagem: ${res['message'] ?? res}');
  }
}

// 5) Inserir interação de Visita Técnica (su_oss_chamado_mensagem / inserir)
Future<void> inserirInteracaoChamado({
  required String idChamado,
  required String idEvento,
  required String mensagem,
  String idResposta = '',
  String status = 'A',
  String tipoCobranca = 'NENHUM',
  String finalizaProcesso = 'N', // S para fechar
}) async {
  final payload = {
    'id_chamado': idChamado,
    'id_evento': idEvento,
    'id_resposta': idResposta,
    'mensagem': mensagem,
    'status': status,
    'tipo_cobranca': tipoCobranca,
    'finaliza_processo': finalizaProcesso,
    // campos de data, gps e equipe podem ficar em branco
    'data_inicio': '',
    'data_final': '',
    'id_tecnico': '',
    'id_evento_status': '',
    'data': '',
    'id_equipe': '',
    'id_proxima_tarefa': '',
    'latitude': '',
    'longitude': '',
    'gps_time': '',
  };

  final res = await _ixcPost(
    'su_oss_chamado_mensagem',
    payload,
    action: 'inserir',
  );
  if (res['type'] != 'success') {
    throw Exception('Falha ao inserir interação: ${res['message'] ?? res}');
  }
}

// 6) Encerrar Chamado → cria uma interação finalizadora
Future<void> encerrarChamado({
  required String idChamado,
  required String mensagemFinal,
  required String idEventoStatus, // ex: '8' ou o evento de encerramento
}) async {
  await inserirInteracaoChamado(
    idChamado: idChamado,
    idEvento: idEventoStatus,
    mensagem: mensagemFinal,
    finalizaProcesso: 'S',
  );
}
