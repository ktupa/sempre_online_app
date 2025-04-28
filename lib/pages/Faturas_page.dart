import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/fatura_card.dart';
import '../services/ixc_api_service.dart';

class FaturasPage extends StatelessWidget {
  final String clientId;
  const FaturasPage({super.key, required this.clientId});

  // ------------------- API -------------------
  Future<List<Map<String, dynamic>>> _fetchFaturas() =>
      listarFaturasDoCliente(clientId);

  Future<Map<String, String>> _fetchPixData(String idAReceber) =>
      getPixInfo(idAReceber);

  // ----------------- helpers -----------------
  String _label(String code, bool atrasada) {
    switch (code) {
      case 'R':
        return 'Recebido';
      case 'P':
        return 'Parcial';
      case 'A':
        return atrasada ? 'Atrasada' : 'A receber';
      default:
        return '—';
    }
  }

  Color _color(String code, bool atrasada) {
    switch (code) {
      case 'R':
        return Colors.blue;
      case 'P':
        return Colors.orange;
      case 'A':
        return atrasada ? Colors.red : Colors.green;
      default:
        return Colors.grey;
    }
  }

  // ---------------- diálogos ----------------
  void _dialog(
    BuildContext ctx, {
    required String title,
    required Widget body,
    required List<Widget> actions,
  }) {
    showGeneralDialog(
      context: ctx,
      barrierDismissible: true,
      barrierLabel: 'Fechar', // 🔥 AQUI 🔥
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder:
          (_, __, ___) => Center(
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    body,
                    const SizedBox(height: 20),
                    Wrap(spacing: 8, children: actions),
                  ],
                ),
              ),
            ),
          ),
      transitionBuilder:
          (_, anim, __, child) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, .1),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
    );
  }

  void _showBoleto(BuildContext ctx, String linha) => _dialog(
    ctx,
    title: 'Boleto',
    body: SelectableText(linha, textAlign: TextAlign.center),
    actions: [
      TextButton.icon(
        icon: const Icon(Icons.copy),
        label: const Text('Copiar'),
        onPressed: () {
          Clipboard.setData(ClipboardData(text: linha));
          Navigator.pop(ctx);
        },
      ),
      TextButton.icon(
        icon: const Icon(Icons.share),
        label: const Text('Compartilhar'),
        onPressed: () {
          Share.share('Boleto:\n$linha');
          Navigator.pop(ctx);
        },
      ),
    ],
  );

  void _showPix(
    BuildContext ctx, {
    required String imgBase64,
    required String copiaCola,
  }) {
    final bytes = base64Decode(imgBase64);
    _dialog(
      ctx,
      title: 'Pagamento via Pix',
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Copie ou escaneie o QR Code abaixo:',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.memory(
              bytes,
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              copiaCola,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      actions: [
        ElevatedButton.icon(
          icon: const Icon(Icons.copy),
          label: const Text('Copiar Código'),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: copiaCola));
            Navigator.pop(ctx);
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(content: Text('Código Pix copiado!')),
            );
          },
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.share),
          label: const Text('Compartilhar'),
          onPressed: () {
            Share.share('Pagamento via Pix:\n$copiaCola');
            Navigator.pop(ctx);
          },
        ),
      ],
    );
  }

  Future<void> _onPix(BuildContext ctx, String idAReceber) async {
    showDialog(
      context: ctx,
      barrierDismissible: false,
      barrierLabel: 'Aguarde', // 👈 isso resolve o erro
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final data = await _fetchPixData(idAReceber);
      Navigator.pop(ctx);

      final qrcode = data['qrcode'];
      final imagemQrcode = data['imagemQrcode'];

      if (qrcode == null ||
          qrcode.isEmpty ||
          imagemQrcode == null ||
          imagemQrcode.isEmpty) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Pix indisponível para esta fatura')),
        );
        return;
      }

      _showPix(ctx, imgBase64: imagemQrcode, copiaCola: qrcode);
    } catch (e) {
      Navigator.pop(ctx);
      ScaffoldMessenger.of(
        ctx,
      ).showSnackBar(SnackBar(content: Text('Erro no Pix: $e')));
    }
  }

  // ----------------- build ------------------
  @override
  Widget build(BuildContext context) {
    final fmtData = DateFormat('dd MMM', 'pt_BR');
    final fmtMoeda = NumberFormat.simpleCurrency(locale: 'pt_BR', name: 'R\$');
    final hoje = DateTime.now();

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchFaturas(),
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Erro: ${snap.error}'));
        }

        final data = snap.data ?? [];

        Map<String, dynamic>? ultPago;
        Map<String, dynamic>? ultParcial;
        final proximas = <Map<String, dynamic>>[];
        final atrasadas = <Map<String, dynamic>>[];

        for (final f in data) {
          final status = f['status']?.toString() ?? '';
          final venc = DateTime.parse(f['data_vencimento'] as String);

          if (status == 'R') {
            if (ultPago == null ||
                venc.isAfter(DateTime.parse(ultPago['data_vencimento']))) {
              ultPago = f;
            }
          } else if (status == 'P') {
            if (ultParcial == null ||
                venc.isAfter(DateTime.parse(ultParcial['data_vencimento']))) {
              ultParcial = f;
            }
          } else if (status == 'A') {
            (venc.isBefore(hoje) ? atrasadas : proximas).add(f);
          }
        }

        proximas.sort(
          (a, b) => a['data_vencimento'].compareTo(b['data_vencimento']),
        );
        atrasadas.sort(
          (a, b) => a['data_vencimento'].compareTo(b['data_vencimento']),
        );

        final mostrarProximas = proximas.take(4).toList();
        final mostrarAtrasadas = atrasadas.take(4).toList();

        Widget card(Map<String, dynamic> f) {
          final status = f['status']?.toString() ?? '';
          final venc = DateTime.parse(f['data_vencimento'] as String);
          final atrasada = status == 'A' && venc.isBefore(hoje);
          final linha =
              (f['linha_digitavel'] ??
                      f['codigo_barras'] ??
                      f['nn_boleto'] ??
                      '')
                  .toString();

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: FaturaCard(
              titulo:
                  f['documento']?.toString().isNotEmpty == true
                      ? f['documento']
                      : f['boleto'] ?? '—',
              valor: fmtMoeda.format(double.tryParse(f['valor'] ?? '0') ?? 0),
              vencimento: fmtData.format(venc),
              status: _label(status, atrasada),
              cor: _color(status, atrasada),
              onPagar: () {
                if (linha.isNotEmpty) _showBoleto(ctx, linha);
              },
              onCodigoBarras: () {
                if (linha.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Fatura não possui código de barras.'),
                    ),
                  );
                } else {
                  _dialog(
                    ctx,
                    title: 'Código de Barras',
                    body: SelectableText(linha),
                    actions: [
                      TextButton.icon(
                        icon: const Icon(Icons.copy),
                        label: const Text('Copiar'),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: linha));
                          Navigator.pop(ctx);
                        },
                      ),
                    ],
                  );
                }
              },
              onQrCode: () => _onPix(ctx, f['id'].toString()),
              onImprimir:
                  (f['gateway_link'] ?? '').toString().isNotEmpty
                      ? () async {
                        final uri = Uri.parse(f['gateway_link']);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        } else {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('Não foi possível abrir link.'),
                            ),
                          );
                        }
                      }
                      : null,
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (mostrarProximas.isNotEmpty) ...[
                const Text(
                  'A receber',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                ...mostrarProximas.map(card),
                const Divider(height: 40),
              ],
              if (mostrarAtrasadas.isNotEmpty) ...[
                const Text(
                  'Atrasadas',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                ...mostrarAtrasadas.map(card),
                const Divider(height: 40),
              ],
              if (ultParcial != null) ...[
                const Text(
                  'Parcial',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                card(ultParcial),
                const Divider(height: 40),
              ],
              if (ultPago != null) ...[
                const Text(
                  'Recebido',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                card(ultPago),
              ],
              if (ultPago == null &&
                  ultParcial == null &&
                  mostrarProximas.isEmpty &&
                  mostrarAtrasadas.isEmpty)
                const Center(child: Text('Nenhuma fatura para exibir.')),
            ],
          ),
        );
      },
    );
  }
}
