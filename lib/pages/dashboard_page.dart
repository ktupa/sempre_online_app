import 'package:flutter/material.dart';
import 'package:sempre_online_app/services/auth_service.dart';
import 'package:sempre_online_app/services/ixc_api_service.dart';
import 'package:sempre_online_app/widgets/ConsumoCard.dart'; // Usa o novo ConsumoCard aqui!

class DashboardPage extends StatefulWidget {
  final Function(int) onNavigateTab;

  const DashboardPage({Key? key, required this.onNavigateTab})
    : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<DashboardInfo> _dashboardFuture;
  late final Map<String, dynamic> _user;

  @override
  void initState() {
    super.initState();
    _user = AuthService().clientData!;
    _dashboardFuture = _loadDashboardInfo(
      clientId: _user['id'].toString(),
      cpf: _user['cnpj_cpf']!,
    );
  }

  Future<DashboardInfo> _loadDashboardInfo({
    required String clientId,
    required String cpf,
  }) async {
    final contratos = await listarContratosDoCliente(clientId);
    if (contratos.isEmpty) throw Exception('Nenhum contrato encontrado.');

    final ativos =
        contratos
            .where((c) => c['status'] == 'A' || c['status'] == 'S')
            .toList();
    final contrato = ativos.isNotEmpty ? ativos.first : contratos.first;
    final contratoId = contrato['id'].toString();

    final radList = await listarRadUsuariosPorContrato(contratoId);
    final rad =
        radList.isNotEmpty
            ? Map<String, dynamic>.from(radList.first)
            : <String, dynamic>{};

    final consumo = await buscarConsumoRealPorContrato(
      contratoId,
    ); // aqui nova função

    final faturas = await listarFaturasDoCliente(clientId);
    final faturaAberta =
        faturas.where((f) => f['status'] == 'A').toList()..sort(
          (a, b) => a['data_vencimento'].compareTo(b['data_vencimento']),
        );
    final faturaAtual = faturaAberta.isNotEmpty ? faturaAberta.first : null;

    final servicosTv = <Map<String, dynamic>>[];
    for (final c in contratos) {
      final tv = await listarPerfisTvContrato(c['id'].toString());
      servicosTv.addAll(tv);
    }

    return DashboardInfo(
      contrato: contrato,
      rad: rad,
      downloadGB: consumo['download'] ?? 0,
      uploadGB: consumo['upload'] ?? 0,
      faturaAtual: faturaAtual,
      tvCount: servicosTv.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final nome = _user['fantasia'] ?? '';
    final cpf = _user['cnpj_cpf'] ?? '';

    return FutureBuilder<DashboardInfo>(
      future: _dashboardFuture,
      builder: (ctx, snap) {
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

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'Olá, $nome!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text('CPF: $cpf', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),

              // Cards organizados
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildCard(
                    onTap: () => widget.onNavigateTab(1),
                    icon: online ? Icons.wifi : Icons.wifi_off,
                    title: 'Conexão',
                    value: ativo ? (online ? 'Online' : 'Offline') : 'Inativa',
                    color:
                        ativo
                            ? (online ? Colors.green : Colors.orange)
                            : Colors.red,
                  ),
                  _buildCard(
                    onTap: null,
                    icon: Icons.data_usage,
                    title: 'Consumo',
                    child: ConsumoCard(
                      // ← Aqui agora mostra download e upload!
                      downloadGB: info.downloadGB,
                      uploadGB: info.uploadGB,
                    ),
                  ),
                  _buildCard(
                    onTap: () => widget.onNavigateTab(3),
                    icon: Icons.receipt_long,
                    title: 'Fatura Atual',
                    value:
                        info.faturaAtual != null
                            ? 'R\$ ${info.faturaAtual!['valor']}'
                            : 'Sem fatura',
                  ),
                  _buildCard(
                    onTap: () => widget.onNavigateTab(2),
                    icon: Icons.tv,
                    title: 'TV Watch',
                    value: '${info.tvCount} perfis',
                  ),
                  _buildCard(
                    onTap: null,
                    icon: Icons.speed,
                    title: 'Velocidade',
                    value: info.contrato['descricao_aux_plano_venda'] ?? '—',
                  ),
                  _buildCard(
                    onTap: () => widget.onNavigateTab(4),
                    icon: Icons.support_agent,
                    title: 'Suporte',
                    value: 'Acesse seus chamados',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    String? value,
    Widget? child,
    VoidCallback? onTap,
    Color? color,
  }) {
    final width = (MediaQuery.of(context).size.width - 48) / 2;
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 28, color: color ?? Colors.teal),
              const SizedBox(height: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              child ??
                  Text(
                    value ?? '',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: color ?? Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

// Atualizado para incluir download/upload
class DashboardInfo {
  final Map<String, dynamic> contrato;
  final Map<String, dynamic> rad;
  final double downloadGB;
  final double uploadGB;
  final Map<String, dynamic>? faturaAtual;
  final int tvCount;

  DashboardInfo({
    required this.contrato,
    required this.rad,
    required this.downloadGB,
    required this.uploadGB,
    required this.faturaAtual,
    required this.tvCount,
  });
}
