import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sempre_online_app/services/ixc_api_service.dart';

class ContractsTab extends StatelessWidget {
  final String cpf;
  final String clientId;

  const ContractsTab({Key? key, required this.cpf, required this.clientId})
    : super(key: key);

  String mapStatusContrato(String status) {
    switch (status) {
      case 'P':
        return 'Pré-contrato';
      case 'A':
        return 'Ativo';
      case 'I':
        return 'Inativo';
      case 'N':
        return 'Negativado';
      case 'D':
        return 'Desistiu';
      default:
        return 'Desconhecido';
    }
  }

  String mapStatusInternet(String statusInternet) {
    switch (statusInternet) {
      case 'A':
        return 'Internet Ativa';
      case 'D':
        return 'Internet Desativada';
      case 'CM':
        return 'Bloqueio Manual';
      case 'CA':
        return 'Bloqueio Automático';
      case 'FA':
        return 'Financeiro em atraso';
      case 'AA':
        return 'Aguardando assinatura';
      default:
        return 'Desconhecido';
    }
  }

  String _mensagemStatusInternet(String status) {
    switch (status) {
      case 'D':
        return 'Sua conexão está desativada.';
      case 'CM':
        return 'Sua conexão foi bloqueada manualmente.';
      case 'CA':
        return 'Sua conexão foi bloqueada automaticamente.';
      case 'FA':
        return 'Sua conexão está bloqueada por atraso financeiro.';
      case 'AA':
        return 'Seu contrato está aguardando assinatura.';
      default:
        return 'Status de conexão desconhecido.';
    }
  }

  String formatDuration(String tempoSegundos) {
    final tempo = int.tryParse(tempoSegundos) ?? 0;
    final duration = Duration(seconds: tempo);
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);

    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String formatBytes(double bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(2)} MB';
  }

  Future<void> _desbloquear(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Liberar Confiança?'),
            content: const Text('Deseja solicitar desbloqueio de confiança?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Confirmar'),
              ),
            ],
          ),
    );

    if (confirmar == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      try {
        await desbloquearConfianca(clientId);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Desbloqueio solicitado com sucesso!')),
        );
      } catch (e) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  Future<void> _assinarContrato(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      throw 'Não foi possível abrir a URL';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: listarContratosDoCliente(clientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        }
        final contratos = snapshot.data ?? [];
        if (contratos.isEmpty) {
          return const Center(child: Text('Nenhum contrato encontrado.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: contratos.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final c = contratos[i];
            final idContrato = c['id'].toString();
            final plano = (c['descricao_aux_plano_venda'] ?? '—') as String;
            final statusContrato = c['status'] ?? '';
            final statusInternet = c['status_internet'] ?? '';
            final assinaturaDigital = c['assinatura_digital'] ?? '';
            final urlAssinatura = c['url_assinatura_digital'] ?? '';
            final dataAtiv = c['data_ativacao'] ?? '—';
            final dataRenov = c['data_renovacao'] ?? '—';
            final flagDesc = c['desbloqueio_confianca'] ?? 'N';
            final ativoDesc = c['desbloqueio_confianca_ativo'] ?? 'N';

            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plano, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(
                          label: Text(mapStatusContrato(statusContrato)),
                          backgroundColor:
                              statusContrato == 'A'
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.red.withOpacity(0.2),
                        ),
                        Chip(
                          label: Text(mapStatusInternet(statusInternet)),
                          backgroundColor:
                              statusInternet == 'A'
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.orange.withOpacity(0.2),
                        ),
                      ],
                    ),
                  ],
                ),
                childrenPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                children: [
                  if (statusInternet != 'A') ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.redAccent,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _mensagemStatusInternet(statusInternet),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.copyWith(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (statusInternet == 'FA') ...[
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(
                                  context,
                                ).popUntil((route) => route.isFirst);
                                Future.delayed(Duration.zero, () {
                                  // Aqui depois vamos mudar para aba de faturas
                                });
                              },
                              icon: const Icon(Icons.receipt_long),
                              label: const Text('Ver Faturas Pendentes'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Text('Ativado em: $dataAtiv'),
                  Text('Renovação: $dataRenov'),
                  const Divider(height: 20),

                  FutureBuilder<Map<String, double>>(
                    future: buscarConsumoRealPorContrato(idContrato),
                    builder: (ctx, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap.hasError)
                        return Text('Erro consumo: ${snap.error}');
                      final consumo = snap.data ?? {};

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Download: ${formatBytes((consumo['download'] ?? 0) * 1024 * 1024 * 1024)}',
                          ),
                          Text(
                            'Upload: ${formatBytes((consumo['upload'] ?? 0) * 1024 * 1024 * 1024)}',
                          ),
                          const Divider(height: 20),
                        ],
                      );
                    },
                  ),

                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: listarRadUsuariosPorContrato(idContrato),
                    builder: (ctx, snap2) {
                      if (snap2.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap2.hasError)
                        return Text('Erro logins: ${snap2.error}');
                      final logins = snap2.data ?? [];

                      return Column(
                        children:
                            logins.map((login) {
                              final loginName = login['login'] ?? '—';
                              final ip = login['ip'] ?? '—';
                              final mac = login['mac'] ?? '—';
                              final tempo = formatDuration(
                                login['tempo_conectado'] ?? '0',
                              );
                              final online = login['online'] == 'S';
                              return ListTile(
                                dense: true,
                                leading: Icon(
                                  online ? Icons.wifi : Icons.wifi_off,
                                  color: online ? Colors.green : Colors.grey,
                                ),
                                title: Text(loginName),
                                subtitle: Text(
                                  'IP: $ip\nMAC: $mac\nTempo conectado: $tempo',
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
                    future: listarServicosExtrasPorContrato(idContrato),
                    builder: (ctx, snap3) {
                      if (snap3.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap3.hasError)
                        return Text('Erro extras: ${snap3.error}');
                      final extras = snap3.data ?? [];

                      return Column(
                        children:
                            extras.map((e) {
                              final nome = e['profile_name'] ?? '—';
                              final plataforma =
                                  (e['plataforma'] ?? '')
                                      .toString()
                                      .toUpperCase();
                              final status =
                                  (e['status_assinante_watch'] == '1')
                                      ? 'Ativo'
                                      : 'Inativo';

                              return ListTile(
                                leading: Icon(
                                  Icons.tv,
                                  color:
                                      status == 'Ativo'
                                          ? Colors.green
                                          : Colors.grey,
                                ),
                                title: Text(nome),
                                subtitle: Text(
                                  'Plataforma: $plataforma\nStatus: $status',
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
                      if (flagDesc == 'P' && ativoDesc == 'N')
                        OutlinedButton.icon(
                          onPressed: () => _desbloquear(context),
                          icon: const Icon(Icons.lock_open),
                          label: const Text('Liberar Confiança'),
                        ),
                      if (assinaturaDigital == 'P' && urlAssinatura.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: () => _assinarContrato(urlAssinatura),
                          icon: const Icon(Icons.edit_document),
                          label: const Text('Assinar Contrato'),
                        ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/os_upgrade',
                            arguments: {'id_contrato': idContrato},
                          );
                        },
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
}
