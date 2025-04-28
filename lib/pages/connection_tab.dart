import 'package:flutter/material.dart';
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

            return ExpansionTile(
              title: Text('#$idContrato — $plano'),
              subtitle: Text(
                '${rads.length} login${rads.length > 1 ? 's' : ''}',
              ),
              children:
                  rads.map((rad) {
                    final login = rad['login'] ?? '—';
                    final ativo = rad['ativo'] == 'S';
                    final online = rad['online'] == 'S';
                    final ip =
                        (rad['ip'] as String?)?.isNotEmpty == true
                            ? rad['ip']
                            : '—';
                    final mac =
                        (rad['mac'] as String?)?.isNotEmpty == true
                            ? rad['mac']
                            : '—';
                    final tempoConectado = formatDuration(
                      rad['tempo_conectado'] ?? '0',
                    );
                    final updated = rad['ultima_atualizacao'] ?? '—';

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
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
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
                            _buildStatusBadge(
                              ativo: ativo,
                              online: online,
                            ), // Adiciona o badge
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('IP: $ip'),
                              Text('MAC: $mac'),
                              Text('Tempo conectado: $tempoConectado'),
                              Text('Download: ${formatBytes(downloadAtual)}'),
                              Text('Upload: ${formatBytes(uploadAtual)}'),
                              Text('Última atualização: $updated'),
                            ],
                          ),
                        ),
                        isThreeLine: true,
                      ),
                    );
                  }).toList(),
            );
          },
        );
      },
    );
  }
}
