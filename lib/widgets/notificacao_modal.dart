import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificacaoModal extends StatefulWidget {
  const NotificacaoModal({Key? key}) : super(key: key);

  @override
  State<NotificacaoModal> createState() => _NotificacaoModalState();
}

class _NotificacaoModalState extends State<NotificacaoModal> {
  List<Map<String, dynamic>> _notificacoes = [];
  bool _loading = true;
  String? _erro;

  Future<void> _carregarNotificacoes() async {
    try {
      final res = await http.get(
        Uri.parse('http://138.117.249.70:8087/notificacoes'),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data is List) {
          setState(() {
            _notificacoes = List<Map<String, dynamic>>.from(data);
            _loading = false;
          });
        } else {
          throw Exception("Resposta inesperada");
        }
      } else {
        throw Exception("Erro HTTP ${res.statusCode}");
      }
    } catch (e) {
      setState(() {
        _erro = 'Erro ao carregar notificações: $e';
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _carregarNotificacoes();
  }

  @override
  Widget build(BuildContext context) {
    final ts = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 400),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.notifications, size: 26),
                  const SizedBox(width: 8),
                  Text(
                    'Notificações',
                    style: ts.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child:
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _erro != null
                      ? Center(
                        child: Text(
                          _erro!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                      : _notificacoes.isEmpty
                      ? const Center(
                        child: Text("Nenhuma notificação encontrada."),
                      )
                      : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notificacoes.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (_, i) {
                          final n = _notificacoes[i];
                          return ListTile(
                            leading: const Icon(Icons.announcement_outlined),
                            title: Text(
                              n['titulo'] ?? '',
                              style: ts.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              n['mensagem'] ?? '',
                              style: ts.bodyMedium,
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
