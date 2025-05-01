import 'package:flutter/material.dart';
import '../services/ixc_api_service.dart';
import '../services/auth_service.dart';

class NovoChamadoModal extends StatefulWidget {
  final String clienteId;
  const NovoChamadoModal({Key? key, required this.clienteId}) : super(key: key);

  @override
  State<NovoChamadoModal> createState() => _NovoChamadoModalState();
}

class _NovoChamadoModalState extends State<NovoChamadoModal> {
  final _tituloCtrl = TextEditingController();
  final _mensagemCtrl = TextEditingController();
  bool _loading = false;

  List<Map<String, dynamic>> _assuntos = [];
  String? _assuntoSelecionadoId;

  @override
  void initState() {
    super.initState();
    _carregarAssuntos();
  }

  Future<void> _carregarAssuntos() async {
    try {
      final regs = await listarAssuntosChamado();
      setState(() {
        _assuntos = regs.where((a) => a['ativo'] == 'S').toList();
        if (_assuntos.isNotEmpty) {
          _assuntoSelecionadoId = _assuntos.first['id'].toString();
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar assuntos: $e')));
    }
  }

  Future<void> _enviarChamado() async {
    final titulo = _tituloCtrl.text.trim();
    final mensagem = _mensagemCtrl.text.trim();
    final assuntoId = _assuntoSelecionadoId;
    if (titulo.isEmpty || mensagem.isEmpty || assuntoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final cliente = AuthService().clientData!;
      await criarChamadoAvancado(
        clienteId: widget.clienteId,
        titulo: titulo,
        mensagem: mensagem,
        idAssunto: assuntoId,
        idDepartamento: '5',
        origemEndereco: 'C',
        prioridade: 'N',
        idLogin: cliente['id_login'].toString(),
        idContrato: cliente['id_contrato'].toString(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Atendimento criado com sucesso!')),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao criar atendimento: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Novo Atendimento'),
      content:
          _assuntos.isEmpty
              ? const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              )
              : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _assuntoSelecionadoId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Assunto',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          _assuntos
                              .map(
                                (a) => DropdownMenuItem(
                                  value: a['id'].toString(),
                                  child: Text(a['assunto'] ?? '—'),
                                ),
                              )
                              .toList(),
                      onChanged:
                          (v) => setState(() => _assuntoSelecionadoId = v),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _tituloCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _mensagemCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Mensagem',
                        border: OutlineInputBorder(),
                      ),
                      minLines: 3,
                      maxLines: 5,
                    ),
                  ],
                ),
              ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _enviarChamado,
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
          ),
          child:
              _loading
                  ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : const Text('Enviar'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _mensagemCtrl.dispose();
    super.dispose();
  }
}
