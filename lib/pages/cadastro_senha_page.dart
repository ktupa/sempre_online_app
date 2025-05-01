import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sempre_online_app/services/ixc_api_service.dart';
import 'login_page.dart';

class CadastroSenhaPage extends StatefulWidget {
  final String cpf;
  final Map<String, dynamic> cliente;

  const CadastroSenhaPage({Key? key, required this.cpf, required this.cliente})
    : super(key: key);

  @override
  State<CadastroSenhaPage> createState() => _CadastroSenhaPageState();
}

class _CadastroSenhaPageState extends State<CadastroSenhaPage> {
  final _dataCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _confirmaCtrl = TextEditingController();

  bool _loading = false;
  String? _erro;

  @override
  void dispose() {
    _dataCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmaCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvarSenha() async {
    final dataInput = _dataCtrl.text.trim();
    final senha = _senhaCtrl.text.trim();
    final confirma = _confirmaCtrl.text.trim();

    if (dataInput.length != 10 || !dataInput.contains('/')) {
      setState(() => _erro = 'Data de nascimento inválida.');
      return;
    }

    if (senha.length < 4 || senha != confirma) {
      setState(() {
        _erro =
            senha != confirma
                ? 'As senhas não coincidem.'
                : 'A senha deve ter ao menos 4 caracteres.';
      });
      return;
    }

    final partes = dataInput.split('/');
    final nascimento = '${partes[2]}-${partes[1]}-${partes[0]}';

    setState(() {
      _erro = null;
      _loading = true;
    });

    try {
      final cliente = widget.cliente;
      final dataServidor = cliente['data_nascimento']?.toString() ?? '';
      if (!dataServidor.startsWith(nascimento)) {
        await showDialog(
          context: context,
          builder:
              (_) => AlertDialog(
                title: const Text('Validação falhou'),
                content: const Text(
                  'A data de nascimento não confere com a base de dados.\n\n'
                  'Entre em contato com nosso atendimento:',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fechar'),
                  ),
                  TextButton(
                    onPressed:
                        () => launchUrl(
                          Uri.parse('https://wa.me/558001004004/?text='),
                        ),
                    child: const Text('WhatsApp'),
                  ),
                  TextButton(
                    onPressed:
                        () => launchUrl(
                          Uri.parse('https://www.instagram.com/semppreonline/'),
                        ),
                    child: const Text('Instagram'),
                  ),
                ],
              ),
        );
        return;
      }

      final id = cliente['id'].toString();
      final cpfLimpo = widget.cpf.replaceAll(RegExp(r'\D'), '');

      await atualizarSenhaComTodosCampos(
        idCliente: id,
        novaSenha: senha,
        novoLogin: cpfLimpo,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha cadastrada com sucesso!')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginPage(savedCpf: cpfLimpo)),
      );
    } catch (e) {
      setState(() => _erro = 'Erro ao salvar senha: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro de Senha')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Confirme sua data de nascimento e defina sua senha.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _dataCtrl,
              decoration: const InputDecoration(
                labelText: 'Data de nascimento (DD/MM/AAAA)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
                TextInputFormatter.withFunction((oldV, newV) {
                  final digits = newV.text.replaceAll(RegExp(r'\D'), '');
                  final buf = StringBuffer();
                  for (var i = 0; i < digits.length; i++) {
                    buf.write(digits[i]);
                    if ((i == 1 || i == 3) && i < digits.length - 1) {
                      buf.write('/');
                    }
                  }
                  return TextEditingValue(
                    text: buf.toString(),
                    selection: TextSelection.collapsed(offset: buf.length),
                  );
                }),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _senhaCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Senha',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmaCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmar Senha',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 20),
            if (_erro != null)
              Text(_erro!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
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
                        : const Icon(Icons.save),
                label: Text(_loading ? 'Salvando...' : 'Salvar Senha'),
                onPressed: _loading ? null : _salvarSenha,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Seu login será o CPF: ${widget.cpf.replaceAll(RegExp(r'\\D'), '')}",
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
