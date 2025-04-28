import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:get/get.dart';

import '../services/ixc_api_service.dart';
import '../services/auth_service.dart';
// import 'chamado_detail_page.dart';
import 'ordem_servico_detail_page.dart';
import '../widgets/NovoChamadoModal.dart'; // Criação novo chamado
import '../widgets/RespostaChamadoModal.dart'; // Responder chamado

class ChamadosPage extends StatefulWidget {
  const ChamadosPage({Key? key}) : super(key: key);

  @override
  State<ChamadosPage> createState() => _ChamadosPageState();
}

class _ChamadosPageState extends State<ChamadosPage>
    with SingleTickerProviderStateMixin {
  late Future<List<Map<String, dynamic>>> _futureChamados;
  late Future<List<Map<String, dynamic>>> _futureOrdens;
  late TabController _tabController;
  late String _clienteId;

  @override
  void initState() {
    super.initState();
    final user = AuthService().clientData!;
    _clienteId = user['id'].toString();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  void _loadData() {
    _futureChamados = listarChamadosCliente(_clienteId);
    _futureOrdens = listarOrdensServicoCliente(_clienteId);
  }

  Color _getStatusColor(String status, BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (status) {
      case 'A':
        return Colors.blue;
      case 'E':
        return Colors.orange;
      case 'F':
        return Colors.green;
      default:
        return cs.onSurface.withOpacity(0.6);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'A':
        return Icons.mark_email_unread_outlined;
      case 'E':
        return Icons.support_agent;
      case 'F':
        return Icons.check_circle_outline;
      default:
        return Icons.help_outline;
    }
  }

  void _openOrdem(Map<String, dynamic> ordem) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrdemServicoDetailPage(ordemServico: ordem),
      ),
    );
  }

  void _responderChamado(Map<String, dynamic> chamado) {
    final status = chamado['status']?.toString() ?? '';
    final idChamado = chamado['id'].toString();
    final tokenChamado = chamado['token'].toString();

    if (status == 'F') {
      Get.snackbar(
        'Chamado Finalizado',
        'Este chamado já foi fechado e não aceita novas mensagens.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (_) => RespostaChamadoModal(
            idChamado: idChamado,
            tokenChamado: tokenChamado,
          ),
    );
  }

  void _abrirNovoChamado() {
    showDialog(
      context: context,
      builder: (_) => NovoChamadoModal(clienteId: _clienteId),
    );
  }

  Widget _buildChamadosList() {
    final cs = Theme.of(context).colorScheme;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _futureChamados,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return _buildShimmer(ctx);
        }
        if (snap.hasError) {
          return Center(
            child: Text(
              'Erro: ${snap.error}',
              style: TextStyle(color: cs.error),
            ),
          );
        }
        final chamados = snap.data!;
        if (chamados.isEmpty) {
          return const Center(child: Text('Nenhum chamado encontrado.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: chamados.length,
          itemBuilder: (ctx, i) {
            final c = chamados[i];
            return _buildChamadoCard(c);
          },
        );
      },
    );
  }

  Widget _buildOrdensList() {
    final cs = Theme.of(context).colorScheme;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _futureOrdens,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return _buildShimmer(ctx);
        }
        if (snap.hasError) {
          return Center(
            child: Text(
              'Erro: ${snap.error}',
              style: TextStyle(color: cs.error),
            ),
          );
        }
        final ordens = snap.data!;
        if (ordens.isEmpty) {
          return const Center(
            child: Text('Nenhuma ordem de serviço encontrada.'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: ordens.length,
          itemBuilder: (ctx, i) {
            final o = ordens[i];
            return _buildOrdemCard(o);
          },
        );
      },
    );
  }

  Widget _buildChamadoCard(Map<String, dynamic> chamado) {
    final cs = Theme.of(context).colorScheme;
    final status = chamado['status'] ?? '';
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _responderChamado(chamado),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              _getStatusIcon(status),
              color: _getStatusColor(status, context),
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chamado['titulo'] ?? '',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Aberto em: ${chamado['data_criacao'] ?? ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chamado['menssagem'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdemCard(Map<String, dynamic> ordem) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openOrdem(ordem),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.build_circle_outlined,
              color: Colors.blueAccent,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ordem #${ordem['id'] ?? ''}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Aberto em: ${ordem['data_abertura'] ?? ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, __) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Shimmer.fromColors(
            baseColor: cs.surface,
            highlightColor: cs.surface.withOpacity(0.7),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(
        backgroundColor: cs.primary,
        title: const Text('Suporte', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Meus Atendimentos'),
            Tab(text: 'Minhas Visitas Técnicas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildChamadosList(), _buildOrdensList()],
      ),
      floatingActionButton:
          _tabController.index == 0
              ? FloatingActionButton(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                onPressed: _abrirNovoChamado,
                child: const Icon(Icons.add),
              )
              : null,
    );
  }
}
