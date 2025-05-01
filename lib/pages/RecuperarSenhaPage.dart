import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sempre_online_app/services/ixc_api_service.dart';

class RecuperarSenhaPage extends StatefulWidget {
  final String cpf;
  const RecuperarSenhaPage({Key? key, required this.cpf}) : super(key: key);

  @override
  State<RecuperarSenhaPage> createState() => _RecuperarSenhaPageState();
}

class _RecuperarSenhaPageState extends State<RecuperarSenhaPage> {
  final _dataNascController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmaSenhaController = TextEditingController();
  String? _erro;
  bool _loading = false;

  Future<void> _redefinirSenha() async {
    final nascimentoInput = _dataNascController.text.trim();
    final senha = _novaSenhaController.text.trim();
    final confirma = _confirmaSenhaController.text.trim();

    if (nascimentoInput.length != 10 || !nascimentoInput.contains('/')) {
      setState(() => _erro = 'Informe a data no formato DD/MM/AAAA.');
      return;
    }

    if (senha.isEmpty || confirma.isEmpty) {
      setState(() => _erro = 'Preencha todos os campos.');
      return;
    }

    if (senha != confirma) {
      setState(() => _erro = 'As senhas não coincidem.');
      return;
    }

    final partes = nascimentoInput.split('/');
    final nascimentoFormatado = '${partes[2]}-${partes[1]}-${partes[0]}';

    setState(() {
      _erro = null;
      _loading = true;
    });

    try {
      final cliente = await buscarClientePorCpf(widget.cpf);
      if (cliente == null) {
        setState(() => _erro = 'Cliente não encontrado.');
        return;
      }

      final nascimentoReal = cliente['data_nascimento']?.toString() ?? '';
      if (!nascimentoReal.startsWith(nascimentoFormatado)) {
        setState(() => _erro = 'Data de nascimento não confere.');
        return;
      }

      final idCliente = cliente['id'].toString();
      final cpf = widget.cpf.replaceAll(RegExp(r'\D'), '');

      await atualizarSenhaComTodosCampos(
        idCliente: idCliente,
        novoLogin: cpf,
        novaSenha: senha,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha redefinida com sucesso!')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _erro = 'Erro ao redefinir senha: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar Senha')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Informe sua data de nascimento e cadastre uma nova senha.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dataNascController,
              decoration: const InputDecoration(
                labelText: 'Data de Nascimento (DD/MM/AAAA)',
                prefixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
                TextInputFormatter.withFunction((oldV, newV) {
                  final t = newV.text.replaceAll(RegExp(r'\D'), '');
                  final b = StringBuffer();
                  for (var i = 0; i < t.length; i++) {
                    b.write(t[i]);
                    if ((i == 1 || i == 3) && i < t.length - 1) b.write('/');
                  }
                  return TextEditingValue(
                    text: b.toString(),
                    selection: TextSelection.collapsed(offset: b.length),
                  );
                }),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _novaSenhaController,
              decoration: const InputDecoration(
                labelText: 'Nova Senha',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmaSenhaController,
              decoration: const InputDecoration(
                labelText: 'Confirmar Senha',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            if (_erro != null)
              Text(_erro!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon:
                    _loading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.refresh),
                label: Text(_loading ? 'Salvando...' : 'Salvar Nova Senha'),
                onPressed: _loading ? null : _redefinirSenha,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
