import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';
import '../services/ixc_api_service.dart';
import '../services/auth_service.dart';

class ChamadosPage extends StatefulWidget {
  const ChamadosPage({Key? key}) : super(key: key);

  @override
  State<ChamadosPage> createState() => _ChamadosPageState();
}

class _ChamadosPageState extends State<ChamadosPage> {
  late Future<List<Map<String, dynamic>>> _futureOrdens;
  late final String _clienteId;

  @override
  void initState() {
    super.initState();
    _clienteId = AuthService().clientData!['id'].toString();
    _futureOrdens = listarOrdensServicoCliente(_clienteId);
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

  Widget _statusTag(String status) {
    final upper = status.toUpperCase();
    final color =
        {
          'A': Colors.orange,
          'E': Colors.blue,
          'F': Colors.green,
          'C': Colors.grey,
        }[upper] ??
        Colors.black45;

    final texto =
        {
          'A': 'Aberta',
          'E': 'Executando',
          'F': 'Finalizada',
          'C': 'Cancelada',
        }[upper] ??
        status;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        texto,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _cardOrdem(Map<String, dynamic> o) {
    final cs = Theme.of(context).colorScheme;
    final id = o['id']?.toString() ?? '---';
    final status = o['status']?.toString() ?? '';
    final dataInicio = o['data_inicio']?.toString();
    final dataFechamento = o['data_fechamento']?.toString();
    final dataAbertura = o['data_abertura']?.toString();

    String resumoData = 'Data não informada';

    try {
      if (dataInicio != null && dataFechamento != null) {
        final inicio = DateTime.parse(dataInicio);
        final fim = DateTime.parse(dataFechamento);
        resumoData =
            '${inicio.day.toString().padLeft(2, '0')}/${inicio.month.toString().padLeft(2, '0')} ${inicio.hour}:${inicio.minute.toString().padLeft(2, '0')}'
            ' até '
            '${fim.day.toString().padLeft(2, '0')}/${fim.month.toString().padLeft(2, '0')} ${fim.hour}:${fim.minute.toString().padLeft(2, '0')}';
      } else if (dataAbertura != null) {
        final abertura = DateTime.parse(dataAbertura);
        resumoData =
            'Aberta em ${abertura.day.toString().padLeft(2, '0')}/${abertura.month.toString().padLeft(2, '0')} às ${abertura.hour}:${abertura.minute.toString().padLeft(2, '0')}';
      }
    } catch (_) {}

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.plumbing_outlined,
                color: Colors.indigo,
                size: 30,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ordem #$id',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (status.isNotEmpty) _statusTag(status),
            ],
          ),
          const SizedBox(height: 6),
          Text(resumoData, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Future<void> _abrirLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.primary,
        title: const Text('Suporte'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed:
                      () => _abrirLink('https://wa.me/558001004004/?text='),
                  icon: const FaIcon(FontAwesomeIcons.whatsapp),
                  label: const Text('Atendimento via WhatsApp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed:
                      () => _abrirLink(
                        'https://www.instagram.com/semppreonline/',
                      ),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Atendimento via Instagram'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
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
          ),
        ],
      ),
    );
  }
}
