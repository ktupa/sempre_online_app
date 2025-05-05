// lib/pages/chamados_page.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../services/ixc_api_service.dart';
import '../services/auth_service.dart';
import 'chamado_detail_page.dart';
import 'novo_chamado_modal.dart';

class ChamadosPage extends StatefulWidget {
  const ChamadosPage({Key? key}) : super(key: key);

  @override
  State<ChamadosPage> createState() => _ChamadosPageState();
}

class _ChamadosPageState extends State<ChamadosPage>
    with SingleTickerProviderStateMixin {
  late Future<List<Map<String, dynamic>>> _futureChamados;
  late Future<List<Map<String, dynamic>>> _futureOrdens;
  late TabController _tab;
  late final String _clienteId;

  String _filtroStatus = 'Abertos';

  @override
  void initState() {
    super.initState();
    _clienteId = AuthService().clientData!['id'].toString();
    _tab = TabController(length: 2, vsync: this)
      ..addListener(() => setState(() {}));
    _loadData();
  }

  void _loadData() {
    List<String>? status;
    if (_filtroStatus == 'Abertos') {
      status = ['N', 'P', 'EP'];
    } else if (_filtroStatus == 'Fechados') {
      status = ['S', 'C'];
    }
    _futureChamados = listarChamadosCliente(_clienteId, statusFiltrar: status);
    _futureOrdens = listarOrdensServicoCliente(_clienteId);
  }

  Color _statusColor(String s) =>
      {
        'N': Colors.blue,
        'P': Colors.orange,
        'EP': Colors.deepOrange,
        'S': Colors.green,
        'C': Colors.grey,
      }[s] ??
      Colors.blueGrey;

  IconData _statusIcon(String s) =>
      {
        'N': Icons.mark_email_unread_outlined,
        'P': Icons.hourglass_bottom,
        'EP': Icons.build_circle_outlined,
        'S': Icons.check_circle_outline,
        'C': Icons.cancel_outlined,
      }[s] ??
      Icons.help_outline;

  void _openChamado(Map<String, dynamic> c) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChamadoDetailPage(chamado: c)),
    );
    _loadData();
    setState(() {});
  }

  Widget _shimmer() {
    final cs = Theme.of(context).colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder:
          (_, __) => Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: Shimmer.fromColors(
              baseColor: cs.surface,
              highlightColor: cs.surfaceVariant,
              child: Container(
                height: 90,
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
    );
  }

  Widget _cardChamado(Map<String, dynamic> c) {
    final cs = Theme.of(context).colorScheme;
    final status =
        (c['su_status'] ?? c['status'] ?? 'N').toString().trim().toUpperCase();
    final titulo = c['titulo']?.toString() ?? 'Sem título';
    final dataCriacao =
        (c['data_criacao'] ?? c['data_cadastro'] ?? '-').toString();
    final mensagem = (c['menssagem'] ?? c['mensagem'] ?? '').toString();
    final naoAssumido = (c['id_usuarios'] ?? '0').toString() == '0';

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openChamado(c),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: naoAssumido ? Border.all(color: Colors.grey) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                Icon(
                  _statusIcon(status),
                  color: _statusColor(status),
                  size: 30,
                ),
                if (naoAssumido)
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 14,
                    color: Colors.orange,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Aberto em: $dataCriacao',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mensagem,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: cs.onSurface.withOpacity(0.7),
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

  // ** AQUI: removemos toda a lógica de detalhes e navegação **
  Widget _cardOrdem(Map<String, dynamic> o) {
    final cs = Theme.of(context).colorScheme;
    final id = o['id']?.toString() ?? '---';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.plumbing_outlined, color: Colors.indigo, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ordem #$id',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.primary,
        title: const Text('Suporte'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tab,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Atendimentos'),
            Tab(text: 'Visitas Técnicas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          // ─────────── Aba "Atendimentos" ───────────
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: DropdownButtonFormField<String>(
                  value: _filtroStatus,
                  decoration: const InputDecoration(
                    labelText: 'Filtrar status',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Abertos', child: Text('Abertos')),
                    DropdownMenuItem(
                      value: 'Fechados',
                      child: Text('Fechados'),
                    ),
                    DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _filtroStatus = val!;
                      _loadData();
                    });
                  },
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _futureChamados,
                  builder: (_, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return _shimmer();
                    }
                    if (snap.hasError) {
                      return Center(child: Text('Erro: ${snap.error}'));
                    }
                    final lst = snap.data!;
                    if (lst.isEmpty) {
                      return const Center(
                        child: Text('Nenhum atendimento encontrado.'),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: lst.length,
                      itemBuilder: (_, i) => _cardChamado(lst[i]),
                    );
                  },
                ),
              ),
            ],
          ),

          // ─────────── Aba "Visitas Técnicas" ───────────
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _futureOrdens,
            builder: (_, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return _shimmer();
              }
              if (snap.hasError) {
                return Center(child: Text('Erro: ${snap.error}'));
              }
              final lst = snap.data!;
              if (lst.isEmpty) {
                return const Center(
                  child: Text('Nenhuma visita técnica registrada.'),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: lst.length,
                itemBuilder: (_, i) => _cardOrdem(lst[i]),
              );
            },
          ),
        ],
      ),
      floatingActionButton:
          _tab.index == 0
              ? FloatingActionButton(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                onPressed: () => _mostrarNovoChamadoModal(context, _clienteId),
                child: const Icon(Icons.add),
                tooltip: 'Novo Atendimento',
              )
              : null,
    );
  }

  void _mostrarNovoChamadoModal(BuildContext context, String clienteId) {
    showDialog(
      context: context,
      builder: (_) => NovoChamadoModal(clienteId: clienteId),
    ).then((_) {
      _loadData();
      setState(() {});
    });
  }
}
