// lib/pages/dashboard_page.dart
//
// Dashboard com seletor de contrato, tiles responsivos
// e teste de velocidade minimalista + tratamento de erros.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sempre_online_app/services/auth_service.dart';
import 'package:sempre_online_app/services/ixc_api_service.dart';
import 'package:sempre_online_app/services/speed_test_service.dart';
import 'package:sempre_online_app/widgets/ConsumoCard.dart';

/// ------------------ prefs helper ------------------
class _Prefs {
  static const _k = 'contrato_pref';
  static Future<void> set(String id) async =>
      (await SharedPreferences.getInstance()).setString(_k, id);

  static Future<String?> get() async =>
      (await SharedPreferences.getInstance()).getString(_k);
}

/// ------------------ page ------------------
class DashboardPage extends StatefulWidget {
  final void Function(int) onNavigateTab;
  const DashboardPage({super.key, required this.onNavigateTab});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<DashboardInfo> _future;
  late final Map<String, dynamic> _user;
  String? _selectedId;

  final SpeedTestService _speedTest = SpeedTestService();

  @override
  void initState() {
    super.initState();
    _user = AuthService().clientData!;
    _loadAll();
  }

  /* --------------- data --------------- */
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

    // contrato ativo
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

    final rad =
        (await listarRadUsuariosPorContrato(contratoId)).firstOrNull ?? {};
    final consumo = await buscarConsumoRealPorContrato(contratoId);
    final tvPerfis = await listarPerfisTvContrato(contratoId);

    final faturas = await listarFaturasDoCliente(clientId);
    faturas.retainWhere(
      (f) => f['id_contrato']?.toString() == contratoId && f['status'] == 'A',
    );
    faturas.sort(
      (a, b) => a['data_vencimento'].compareTo(b['data_vencimento']),
    );

    return DashboardInfo(
      contrato: contrato,
      contratos: contratos,
      rad: rad,
      downloadGB: consumo['download'] ?? 0,
      uploadGB: consumo['upload'] ?? 0,
      faturaAtual: faturas.firstOrNull,
      tvCount: tvPerfis.length,
    );
  }

  /* --------------- helpers --------------- */
  Widget _tag({
    required IconData icon,
    required String label,
    required Color bg,
    required Color fg,
  }) => Container(
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

  /* --------------- speed-test --------------- */
  Future<void> _showSpeedTestModal(BuildContext context) async {
    // pré-aviso
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (dlgCtx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Instruções para Teste'),
            content: const Text(
              'Para resultados precisos:\n'
              '• Use Wi-Fi 5 GHz se possível\n'
              '• Fique próximo ao roteador\n\n'
              'Iniciar agora?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dlgCtx, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dlgCtx, true),
                child: const Text('Iniciar'),
              ),
            ],
          ),
    );
    if (ok != true) return;

    double? dl, ul;
    Timer? watchdog; // encerra se travar

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (sbCtx) => StatefulBuilder(
            builder: (sbCtx2, setState) {
              // dispara 1×
              if (dl == null) {
                watchdog = Timer(const Duration(seconds: 15), () {
                  if (Navigator.of(sbCtx2).canPop()) Navigator.pop(sbCtx2);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Não foi possível completar o teste de velocidade.\n'
                        'Verifique sua conexão e tente novamente.',
                      ),
                      backgroundColor: Colors.red.shade600,
                    ),
                  );
                });

                _speedTest
                    .testarVelocidadeAPI()
                    .then((res) {
                      watchdog?.cancel();
                      setState(() {
                        dl = res['download'];
                        ul = res['upload'];
                      });
                    })
                    .catchError((_) {
                      watchdog?.cancel();
                      Navigator.pop(sbCtx2);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Não foi possível completar o teste de velocidade.\n'
                            'Verifique sua conexão e tente novamente.',
                          ),
                          backgroundColor: Colors.red.shade600,
                        ),
                      );
                    });
              }

              // progresso
              if (dl == null) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text('Teste de Velocidade'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SizedBox(height: 16),
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Medindo download e upload...'),
                    ],
                  ),
                );
              }

              // resultado
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text('Resultado'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MiniRow(
                      icon: Icons.download,
                      label: 'DOWNLOAD',
                      value: '${dl!.toStringAsFixed(1)} Mbps',
                      color: Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _MiniRow(
                      icon: Icons.upload,
                      label: 'UPLOAD',
                      value: '${ul!.toStringAsFixed(1)} Mbps',
                      color: Colors.blue,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(sbCtx2),
                    child: const Text('Fechar'),
                  ),
                ],
              );
            },
          ),
    );
  }

  /* --------------- seletor de contrato --------------- */
  Future<void> _showContratoSelector() async {
    final clientId = _user['id'].toString();
    final todos = await listarContratosDoCliente(clientId);
    final ativos = todos.where((c) => c['status'] == 'A').toList();
    if (ativos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum contrato ativo encontrado.')),
      );
      return;
    }

    final faturas = await listarFaturasDoCliente(clientId);
    final Map<String, int> emAberto = {};
    for (final f in faturas) {
      if (f['status'] != 'A') continue;
      final id = f['id_contrato']?.toString();
      if (id != null) emAberto[id] = (emAberto[id] ?? 0) + 1;
    }

    String _endCliente() {
      final p = _user;
      return [
        p['endereco'] ?? '',
        if ('${p['numero']}'.isNotEmpty) 'Nº ${p['numero']}',
        if ('${p['bairro']}'.isNotEmpty) p['bairro'],
        if ('${p['cidade']}'.isNotEmpty && '${p['cidade']}' != '0') p['cidade'],
      ].where((e) => e.toString().trim().isNotEmpty).join(' - ');
    }

    final escolhido = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (sheetCtx) => SafeArea(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: ativos.length,
              itemBuilder: (_, i) {
                final c = ativos[i];
                final id = c['id'].toString();
                final plano = (c['contrato'] ?? '').toString();

                final endAux = [
                      c['endereco'],
                      if ('${c['numero']}'.isNotEmpty) 'Nº ${c['numero']}',
                      c['bairro'],
                      if (c['cidade'] != null && '${c['cidade']}' != '0')
                        c['cidade'],
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
                    onTap: () => Navigator.pop(sheetCtx, id),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
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

    if (escolhido != null && escolhido != _selectedId) {
      await _Prefs.set(escolhido);
      _loadAll();
    }
  }

  /* --------------- build --------------- */
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nome = _user['fantasia'] ?? '';

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

        final tiles = <_DashTile>[
          _DashTile(
            icon: online ? Icons.wifi : Icons.wifi_off,
            title: 'Conexão',
            value: ativo ? (online ? 'Online' : 'Offline') : 'Inativa',
            color: ativo ? (online ? Colors.green : Colors.orange) : Colors.red,
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
            onTap: () => _showSpeedTestModal(context),
          ),
          _DashTile(
            icon: Icons.support_agent,
            title: 'Suporte',
            value: 'Chamados',
            onTap: () => widget.onNavigateTab(4),
          ),
        ];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              // cabeçalho
              Column(
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Olá, ${nome.toUpperCase()}!',
                      style: theme.textTheme.headlineSmall!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (info.contratos.where((c) => c['status'] == 'A').length >
                      1)
                    TextButton.icon(
                      onPressed: _showContratoSelector,
                      icon: const Icon(Icons.swap_horiz, color: Colors.white),
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
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // grid
              Expanded(
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(
                    bottom: kBottomNavigationBarHeight + 16,
                  ),
                  itemCount: tiles.length,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 175,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.0,
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

/* ---------- widgets auxiliares ---------- */

class _MiniRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _MiniRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 8),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(.7),
              height: 1.2,
            ),
          ),
        ],
      ),
    ],
  );
}

/// tile
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
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.04),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: color ?? theme.colorScheme.primary),
            const SizedBox(height: 8),
            if (embed != null)
              Expanded(child: embed!)
            else if (value != null)
              Text(
                value!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium!.copyWith(
                  color: color ?? theme.colorScheme.primary,
                ),
              ),
            const Spacer(),
            Text(title, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/* ---------- modelo ---------- */
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

/* ---------- extensão ---------- */
extension FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
