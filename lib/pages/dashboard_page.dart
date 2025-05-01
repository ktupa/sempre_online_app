// lib/pages/dashboard_page.dart
//
// Dashboard: mostra apenas o contrato escolhido. O seletor exibe
//   – ID (#)  cinza
//   – Plano   verde
//   – Endereço azul
// e a fatura/consumo são filtrados pelo contrato selecionado.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sempre_online_app/services/auth_service.dart';
import 'package:sempre_online_app/services/ixc_api_service.dart';
import 'package:sempre_online_app/widgets/ConsumoCard.dart';

/* ============================================================= */
/*  Shared-prefs helper – guarda o id do contrato selecionado      */
/* ============================================================= */
class _Prefs {
  static const _k = 'contrato_pref';

  static Future<void> set(String id) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_k, id);
  }

  static Future<String?> get() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_k);
  }
}

/* ============================================================= */
/*                        DASHBOARD PAGE                          */
/* ============================================================= */
class DashboardPage extends StatefulWidget {
  final void Function(int) onNavigateTab;

  const DashboardPage({super.key, required this.onNavigateTab});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<DashboardInfo> _future;
  late final Map<String, dynamic> _user;
  String? _selectedId; // id do contrato atualmente em uso

  @override
  void initState() {
    super.initState();
    _user = AuthService().clientData!;
    _loadAll();
  }

  /* -------------------- carga principal -------------------- */
  void _loadAll() async {
    _selectedId = await _Prefs.get();
    setState(() {
      _future = _buildDashboard(
        clientId: _user['id'].toString(),
        selectedContrato: _selectedId,
      );
    });
  }

  Future<DashboardInfo> _buildDashboard({
    required String clientId,
    String? selectedContrato,
  }) async {
    final contratos = await listarContratosDoCliente(clientId);
    if (contratos.isEmpty) throw Exception('Nenhum contrato encontrado.');

    // — contrato escolhido
    Map<String, dynamic> contrato;
    if (selectedContrato != null) {
      contrato = contratos.firstWhere(
        (c) => c['id'].toString() == selectedContrato,
        orElse: () => contratos.first,
      );
    } else {
      final ativos = contratos.where((c) => c['status'] == 'A');
      contrato = ativos.isNotEmpty ? ativos.first : contratos.first;
    }
    final contratoId = contrato['id'].toString();

    // — dados complementares
    final rad =
        (await listarRadUsuariosPorContrato(contratoId)).firstOrNull ?? {};
    final consumo = await buscarConsumoRealPorContrato(contratoId);
    final tvPerfis = await listarPerfisTvContrato(contratoId);

    // — faturas só DESSE contrato
    final faturas = await listarFaturasDoCliente(clientId);
    final doContrato =
        faturas
            .where(
              (f) =>
                  f['id_contrato']?.toString() == contratoId &&
                  f['status'] == 'A',
            )
            .toList()
          ..sort(
            (a, b) => a['data_vencimento'].compareTo(b['data_vencimento']),
          );
    final faturaAtual = doContrato.firstOrNull;

    return DashboardInfo(
      contrato: contrato,
      contratos: contratos,
      rad: rad,
      downloadGB: consumo['download'] ?? 0,
      uploadGB: consumo['upload'] ?? 0,
      faturaAtual: faturaAtual,
      tvCount: tvPerfis.length,
    );
  }

  /* ---------------------- helper chip ---------------------- */
  Widget _tag({
    required IconData icon,
    required String label,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: fg),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /* ----------------- seletor de contrato ------------------- */
  Future<void> _showContratoSelector() async {
    final clientId = _user['id'].toString();

    // 1) CONTRATOS ATIVOS
    final todos = await listarContratosDoCliente(clientId);
    final ativos = todos.where((c) => c['status'] == 'A').toList();
    if (ativos.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum contrato ativo encontrado.')),
        );
      }
      return;
    }

    // 2) Qtd de faturas em aberto por contrato
    final faturas = await listarFaturasDoCliente(clientId);
    final Map<String, int> emAberto = {};
    for (final f in faturas) {
      if (f['status'] != 'A') continue;
      final id = f['id_contrato']?.toString();
      if (id != null) emAberto[id] = (emAberto[id] ?? 0) + 1;
    }

    // 3) Endereço fallback = endereço do cliente
    String _endCliente() {
      final p = _user;
      return [
        p['endereco'] ?? '',
        if ((p['numero'] ?? '').toString().isNotEmpty) 'Nº ${p['numero']}',
        if ((p['bairro'] ?? '').toString().isNotEmpty) p['bairro'],
        if ((p['cidade'] ?? '').toString().isNotEmpty &&
            p['cidade'].toString() != '0')
          p['cidade'],
      ].where((e) => e.toString().trim().isNotEmpty).join(' - ');
    }

    /* ---------- Bottom-sheet ---------- */
    final escolhido = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => SafeArea(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: ativos.length,
              itemBuilder: (_, i) {
                final c = ativos[i];
                final id = c['id'].toString();
                final plano = (c['contrato'] ?? '').toString();

                final endAux = [
                      c['endereco'],
                      if ((c['numero'] ?? '').toString().isNotEmpty)
                        'Nº ${c['numero']}',
                      c['bairro'],
                      (c['cidade'] != null && c['cidade'].toString() != '0')
                          ? c['cidade']
                          : '',
                    ]
                    .where((e) => e != null && e.toString().trim().isNotEmpty)
                    .join(' - ');
                final endereco = endAux.isNotEmpty ? endAux : _endCliente();

                final aberto = emAberto[id] ?? 0;
                final ativoAtual = id == _selectedId;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.pop(context, id),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          /* --------- Tags --------- */
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _tag(
                                  icon: Icons.confirmation_number,
                                  label: '#$id',
                                  bg: Colors.grey.shade200,
                                  fg: Colors.grey.shade700,
                                ),
                                if (plano.isNotEmpty)
                                  _tag(
                                    icon: Icons.wifi_tethering_rounded,
                                    label: plano,
                                    bg: Colors.green.shade50,
                                    fg: const Color(0xFF2E7D32),
                                  ),
                                if (endereco.isNotEmpty)
                                  _tag(
                                    icon: Icons.home_work_outlined,
                                    label: endereco,
                                    bg: Colors.blue.shade50,
                                    fg: Colors.blue.shade800,
                                  ),
                              ],
                            ),
                          ),
                          /* ---- badges / status ---- */
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (aberto > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$aberto em aberto',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              if (ativoAtual)
                                const Padding(
                                  padding: EdgeInsets.only(top: 6),
                                  child: Icon(Icons.check, color: Colors.green),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
    );

    // 4) salva & recarrega se mudou
    if (escolhido != null && escolhido != _selectedId) {
      await _Prefs.set(escolhido);
      _loadAll();
    }
  }

  /* ------------------------- UI ------------------------- */
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nome = _user['fantasia'] ?? '';
    final cpf = _user['cnpj_cpf'] ?? '';

    return FutureBuilder<DashboardInfo>(
      future: _future,
      builder: (_, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Erro: ${snap.error}'));
        }

        final info = snap.data!;
        final rad = info.rad;
        final online = rad['online'] == 'S';
        final ativo = rad['ativo'] == 'S';

        /* ---- blocos ---- */
        final tiles = <_DashTile>[
          _DashTile(
            icon: online ? Icons.wifi : Icons.wifi_off,
            title: 'Conexão',
            value: ativo ? (online ? 'Online' : 'Offline') : 'Inativa',
            color:
                ativo
                    ? (online ? Colors.green : Colors.orange)
                    : Colors.redAccent,
            onTap: () => widget.onNavigateTab(1),
          ),
          _DashTile(
            icon: Icons.data_usage,
            title: 'Consumo',
            embed: ConsumoCard(
              downloadGB: info.downloadGB,
              uploadGB: info.uploadGB,
            ),
          ),
          _DashTile(
            icon: Icons.receipt_long,
            title: 'Fatura Atual',
            value:
                info.faturaAtual != null
                    ? 'R\$ ${info.faturaAtual!['valor']}'
                    : 'Sem fatura',
            onTap: () => widget.onNavigateTab(3),
          ),
          _DashTile(
            icon: Icons.tv,
            title: 'TV Watch',
            value: '${info.tvCount} perfis',
            onTap: () => widget.onNavigateTab(2),
          ),
          _DashTile(
            icon: Icons.speed,
            title: 'Velocidade',
            value: info.contrato['descricao_aux_plano_venda'] ?? '—',
          ),
          _DashTile(
            icon: Icons.support_agent,
            title: 'Suporte',
            value: 'Acesse seus chamados',
            onTap: () => widget.onNavigateTab(4),
          ),
        ];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /* ---------- cabeçalho ---------- */
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Olá, ${nome.toUpperCase()}!',
                          style: theme.textTheme.headlineSmall!.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('CPF: $cpf', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),

                  if (info.contratos.where((c) => c['status'] == 'A').length >
                      1)
                    TextButton.icon(
                      onPressed: _showContratoSelector,
                      icon: const Icon(
                        Icons.swap_horiz,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Escolher contrato',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF0F6B56),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              /* ------------- grid ------------- */
              Expanded(
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: tiles.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.05,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemBuilder: (_, i) => tiles[i].build(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/* ============================================================= */
/*               MODELO DE DADOS LOCAL (Dashboard)               */
/* ============================================================= */
class DashboardInfo {
  final Map<String, dynamic> contrato;
  final List<Map<String, dynamic>> contratos;
  final Map<String, dynamic> rad;
  final double downloadGB;
  final double uploadGB;
  final Map<String, dynamic>? faturaAtual;
  final int tvCount;

  DashboardInfo({
    required this.contrato,
    required this.contratos,
    required this.rad,
    required this.downloadGB,
    required this.uploadGB,
    required this.faturaAtual,
    required this.tvCount,
  });
}

/* ============================================================= */
/*                    CARD REUTILIZÁVEL                           */
/* ============================================================= */
class _DashTile {
  final IconData icon;
  final String title;
  final String? value;
  final Widget? embed;
  final VoidCallback? onTap;
  final Color? color;

  _DashTile({
    required this.icon,
    required this.title,
    this.value,
    this.embed,
    this.onTap,
    this.color,
  });

  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.06),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 30, color: color ?? theme.colorScheme.primary),
            embed ??
                Text(
                  value ?? '',
                  style: theme.textTheme.titleLarge!.copyWith(
                    color: color ?? theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            Text(title, style: theme.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

/* ============================================================= */
/*           pequena extensão para evitar IndexError             */
/* ============================================================= */
extension FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
