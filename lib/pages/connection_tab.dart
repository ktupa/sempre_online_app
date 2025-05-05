// lib/pages/connection_tab.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sempre_online_app/services/ixc_api_service.dart';

class ConnectionTab extends StatelessWidget {
  final String cpf;
  final String clientId;

  const ConnectionTab({Key? key, required this.cpf, required this.clientId})
    : super(key: key);

  String formatDuration(String tempoSegundos) {
    final tempo = int.tryParse(tempoSegundos) ?? 0;
    final duration = Duration(seconds: tempo);
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    if (days > 0) return '${days}d ${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  String formatBytes(double bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(2)} MB';
  }

  String formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('ddMMyyyy').format(dt);
    } catch (_) {
      return iso;
    }
  }

  Widget _buildStatusBadge({required bool ativo, required bool online}) {
    Color color;
    if (!ativo) {
      color = Colors.red;
    } else if (online) {
      color = Colors.green;
    } else {
      color = Colors.orange;
    }

    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Future<void> _confirmarEDerrubar(
    BuildContext context,
    String radId,
    String login,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Deseja reiniciar a conexão?'),
            content: Text(
              'Você está prestes a derrubar a conexão do login "$login". Deseja continuar?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Derrubar'),
              ),
            ],
          ),
    );

    if (ok == true) {
      try {
        await desconectarCliente(radId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login $login desconectado com sucesso.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao desconectar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchContratosComRad(clientId),
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Erro: ${snap.error}'));
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return const Center(child: Text('Nenhuma conexão encontrada.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: list.length,
          itemBuilder: (ctx, i) {
            final entry = list[i];
            final contrato = entry['contrato'] as Map<String, dynamic>;
            final rads = entry['radusuarios'] as List<Map<String, dynamic>>;

            final idContrato = contrato['id']?.toString() ?? '—';
            final plano =
                (contrato['descricao_aux_plano_venda'] as String?)
                            ?.isNotEmpty ==
                        true
                    ? contrato['descricao_aux_plano_venda']
                    : (contrato['contrato'] ?? '—');
            final loginCount = rads.length;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                childrenPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                title: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _tag(
                      icon: Icons.confirmation_number,
                      label: '#$idContrato',
                      bg: Colors.grey.shade200,
                      fg: Colors.grey.shade700,
                    ),
                    _tag(
                      icon: Icons.wifi_tethering_rounded,
                      label: plano,
                      bg: Colors.green.shade50,
                      fg: const Color(0xFF2E7D32),
                    ),
                    _tag(
                      icon: Icons.person,
                      label: '$loginCount login${loginCount > 1 ? 's' : ''}',
                      bg: Colors.blue.shade50,
                      fg: Colors.blue.shade800,
                    ),
                  ],
                ),
                children:
                    rads.map((rad) {
                      final login = rad['login'] ?? '—';
                      final ativo = rad['ativo'] == 'S';
                      final online = rad['online'] == 'S';
                      // final ip =
                      //     (rad['ip'] as String?)?.isNotEmpty == true
                      //         ? rad['ip']
                      //         : '—';
                      final mac =
                          (rad['mac'] as String?)?.isNotEmpty == true
                              ? rad['mac']
                              : '—';
                      final tempoConectado = formatDuration(
                        rad['tempo_conectado'] ?? '0',
                      );
                      final updatedRaw = rad['ultima_atualizacao'] ?? '—';
                      final updated =
                          updatedRaw != '—' ? formatDate(updatedRaw) : '—';
                      final radId = rad['id']?.toString() ?? '';

                      final downloadAtual =
                          double.tryParse(
                            rad['download_atual']?.toString() ?? '0',
                          ) ??
                          0;
                      final uploadAtual =
                          double.tryParse(
                            rad['upload_atual']?.toString() ?? '0',
                          ) ??
                          0;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: Icon(
                            ativo
                                ? (online ? Icons.wifi : Icons.wifi_off)
                                : Icons.cancel,
                            color:
                                ativo
                                    ? (online ? Colors.green : Colors.orange)
                                    : Colors.red,
                          ),
                          title: Row(
                            children: [
                              Text(
                                login,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildStatusBadge(ativo: ativo, online: online),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Text('IP: $ip'),
                                Text('MAC: $mac'),
                                Text('Tempo conectado: $tempoConectado'),
                                Text('Download: ${formatBytes(downloadAtual)}'),
                                Text('Upload: ${formatBytes(uploadAtual)}'),
                                Text('Última atualização: $updated'),
                              ],
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.restart_alt_rounded),
                            tooltip: 'Derrubar conexão',
                            color: Colors.red.shade600,
                            onPressed:
                                () =>
                                    _confirmarEDerrubar(context, radId, login),
                          ),
                          isThreeLine: true,
                        ),
                      );
                    }).toList(),
              ),
            );
          },
        );
      },
    );
  }
}
