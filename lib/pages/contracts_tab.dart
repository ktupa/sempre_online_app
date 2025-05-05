// lib/pages/contracts_tab.dart
import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';
import 'package:sempre_online_app/services/ixc_api_service.dart';
import 'package:sempre_online_app/services/auth_service.dart';

class ContractsTab extends StatelessWidget {
  final String cpf;
  final String clientId;
  final void Function(int) onNavigateTab;

  const ContractsTab({
    Key? key,
    required this.cpf,
    required this.clientId,
    required this.onNavigateTab,
  }) : super(key: key);

  /* ------------ helpers de texto ------------ */

  String mapStatusContrato(String s) => switch (s) {
    'P' => 'Pré-contrato',
    'A' => 'Ativo',
    'I' => 'Inativo',
    'N' => 'Negativado',
    'D' => 'Desistiu',
    _ => 'Desconhecido',
  };

  String mapStatusInternet(String s) => switch (s) {
    'A' => 'Internet Ativa',
    'D' => 'Internet Desativada',
    'CM' => 'Bloqueio Manual',
    'CA' => 'Bloqueio Automático',
    'FA' => 'Financeiro em atraso',
    'AA' => 'Aguardando assinatura',
    _ => 'Desconhecido',
  };

  String _mensagemStatusInternet(String s) => switch (s) {
    'D' => 'Sua conexão está desativada.',
    'CM' => 'Sua conexão foi bloqueada manualmente.',
    'CA' => 'Sua conexão foi bloqueada automaticamente.',
    'FA' => 'Sua conexão está bloqueada por atraso financeiro.',
    'AA' => 'Seu contrato está aguardando assinatura.',
    _ => 'Status de conexão desconhecido.',
  };

  String formatDuration(String v) {
    final seg = int.tryParse(v) ?? 0;
    final d = Duration(seconds: seg);
    if (d.inDays > 0)
      return '${d.inDays}d ${d.inHours % 24}h ${d.inMinutes % 60}m';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${d.inMinutes}m';
  }

  String _formatBytes(double b) =>
      '${(b / (1024 * 1024)).toStringAsFixed(2)} MB';

  /* ------------ ações ------------ */

  Future<void> _desbloquear(BuildContext ctx, String idContrato) async {
    /* … mesma implementação … */
  }

  Future<void> _assinarContrato(BuildContext ctx, String url) async {
    /* … mesma implementação … */
  }

  /* ------------ helper de Chip ------------ */

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
          Text(
            label,
            style: TextStyle(fontSize: 11, color: fg),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /* ------------ UI ------------ */

  @override
  Widget build(BuildContext context) {
    // endereço do cliente para fallback
    final cliente = AuthService().clientData!;
    final enderecoCliente = [
      cliente['endereco'] ?? '',
      if ((cliente['numero'] ?? '').toString().isNotEmpty)
        'Nº ${cliente['numero']}',
      if ((cliente['bairro'] ?? '').toString().isNotEmpty) cliente['bairro'],
      if ((cliente['cidade'] ?? '').toString().isNotEmpty &&
          cliente['cidade'].toString() != '0')
        cliente['cidade'],
    ].where((e) => e.toString().trim().isNotEmpty).join(' - ');

    return FutureBuilder(
      future: Future.wait([
        listarContratosDoCliente(clientId), // 0
        listarFaturasDoCliente(clientId), // 1
      ]),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Erro: ${snap.error}'));
        }

        final contratosAll = snap.data![0] as List<Map<String, dynamic>>;
        final faturas = snap.data![1] as List<Map<String, dynamic>>;

        // só contratos ativos
        final contratos =
            contratosAll.where((c) => c['status'] == 'A').toList();
        if (contratos.isEmpty) {
          return const Center(child: Text('Nenhum contrato ativo.'));
        }

        // contas abertas por contrato
        final fatAbertas = <String, int>{};
        for (final f in faturas) {
          if (f['status'] != 'A') continue;
          final idc = f['id_contrato']?.toString();
          if (idc != null) fatAbertas[idc] = (fatAbertas[idc] ?? 0) + 1;
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: contratos.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final c = contratos[i];
            final id = c['id'].toString();
            final plano = (c['contrato'] ?? '').toString();
            final enderecoContrato = [
                  c['endereco'],
                  if ((c['numero'] ?? '').toString().isNotEmpty)
                    'Nº ${c['numero']}',
                  c['bairro'],
                  if ((c['cidade'] ?? '').toString() != '0') c['cidade'],
                ]
                .where((e) => e != null && e.toString().trim().isNotEmpty)
                .join(' - ');
            final endereco =
                enderecoContrato.isNotEmpty
                    ? enderecoContrato
                    : enderecoCliente;

            final statusContrato = mapStatusContrato(c['status'] ?? '');
            final statusInternet = mapStatusInternet(
              c['status_internet'] ?? '',
            );
            final abertas = fatAbertas[id] ?? 0;

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                childrenPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),

                // ** aqui substituímos o title anterior por um Wrap de tags **
                title: LayoutBuilder(
                  builder:
                      (ctx, constraints) => ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth,
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            _tag(
                              icon: Icons.confirmation_number,
                              label: '#$id',
                              bg: Colors.grey.shade200,
                              fg: Colors.grey.shade700,
                            ),
                            _tag(
                              icon: Icons.wifi_tethering_rounded,
                              label: plano.isNotEmpty ? plano : '—',
                              bg: Colors.green.shade50,
                              fg: const Color(0xFF2E7D32),
                            ),
                            _tag(
                              icon: Icons.home_work_outlined,
                              label: endereco,
                              bg: Colors.blue.shade50,
                              fg: Colors.blue.shade800,
                            ),
                            if (abertas > 0)
                              _tag(
                                icon: Icons.receipt_long,
                                label: '$abertas em aberto',
                                bg: Colors.orange.shade100,
                                fg: Colors.orange.shade800,
                              ),
                          ],
                        ),
                      ),
                ),

                // ** mantemos os children exatamente como antes **
                children: [
                  if (c['status_internet'] != 'A') ...[
                    _buildAvisoBloqueio(context, c['status_internet'] ?? ''),
                    const SizedBox(height: 16),
                  ],
                  Text('Ativado em: ${c['data_ativacao'] ?? '—'}'),
                  Text('Renovação:   ${c['data_renovacao'] ?? '—'}'),
                  const Divider(height: 20),

                  FutureBuilder<Map<String, double>>(
                    future: buscarConsumoRealPorContrato(id),
                    builder: (_, s) {
                      if (s.connectionState != ConnectionState.done)
                        return const Center(child: CircularProgressIndicator());
                      if (s.hasError) return Text('Erro consumo: ${s.error}');
                      final d = s.data ?? {};
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Download: ${_formatBytes((d['download'] ?? 0) * 1024 * 1024 * 1024)}',
                          ),
                          Text(
                            'Upload:    ${_formatBytes((d['upload'] ?? 0) * 1024 * 1024 * 1024)}',
                          ),
                          const Divider(height: 20),
                        ],
                      );
                    },
                  ),

                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: listarRadUsuariosPorContrato(id),
                    builder: (_, s) {
                      if (s.connectionState != ConnectionState.done)
                        return const Center(child: CircularProgressIndicator());
                      if (s.hasError) return Text('Erro logins: ${s.error}');
                      final logins = s.data ?? [];
                      return Column(
                        children:
                            logins.map((l) {
                              final online = l['online'] == 'S';
                              return ListTile(
                                dense: true,
                                leading: Icon(
                                  online ? Icons.wifi : Icons.wifi_off,
                                  color: online ? Colors.green : Colors.grey,
                                ),
                                title: Text(l['login'] ?? '—'),
                                subtitle: Text(
                                  'IP: ${l['ip'] ?? '—'}  ·  MAC: ${l['mac'] ?? '—'}\n'
                                  'Tempo: ${formatDuration(l['tempo_conectado'] ?? '0')}',
                                ),
                              );
                            }).toList(),
                      );
                    },
                  ),

                  const Divider(height: 20),

                  Text(
                    'Serviços Extras',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: listarServicosExtrasPorContrato(id),
                    builder: (_, s) {
                      if (s.connectionState != ConnectionState.done)
                        return const Center(child: CircularProgressIndicator());
                      if (s.hasError) return Text('Erro extras: ${s.error}');
                      final extras = s.data ?? [];
                      return Column(
                        children:
                            extras.map((e) {
                              final ativo = e['status_assinante_watch'] == '1';
                              return ListTile(
                                leading: Icon(
                                  Icons.tv,
                                  color: ativo ? Colors.green : Colors.grey,
                                ),
                                title: Text(e['profile_name'] ?? '—'),
                                subtitle: Text(
                                  'Plataforma: ${(e['plataforma'] ?? '').toString().toUpperCase()}\n'
                                  'Status: ${ativo ? 'Ativo' : 'Inativo'}',
                                ),
                              );
                            }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (c['desbloqueio_confianca'] == 'P' &&
                          c['desbloqueio_confianca_ativo'] == 'N')
                        OutlinedButton.icon(
                          onPressed: () => _desbloquear(context, id),
                          icon: const Icon(Icons.lock_open),
                          label: const Text('Liberar Confiança'),
                        ),
                      if (c['assinatura_digital'] == 'P' &&
                          (c['url_assinatura_digital'] as String?)
                                  ?.isNotEmpty ==
                              true)
                        ElevatedButton.icon(
                          onPressed:
                              () => _assinarContrato(
                                context,
                                c['url_assinatura_digital'],
                              ),
                          icon: const Icon(Icons.edit_document),
                          label: const Text('Assinar Contrato'),
                        ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed:
                            () => Navigator.pushNamed(
                              context,
                              '/os_upgrade',
                              arguments: {'id_contrato': id},
                            ),
                        icon: const Icon(Icons.upgrade),
                        label: const Text('Upgrade'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /* ---- aviso + botão pagar fatura (reutilizado) ---- */
  Widget _buildAvisoBloqueio(BuildContext ctx, String statusInternet) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(.08),
        border: Border.all(color: Colors.redAccent),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _mensagemStatusInternet(statusInternet),
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => onNavigateTab(3),
            icon: const Icon(Icons.payment),
            label: const Text('Pagar Fatura'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
