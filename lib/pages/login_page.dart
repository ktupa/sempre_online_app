// lib/pages/login_page.dart

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sempre_online_app/services/auth_service.dart';
import 'package:sempre_online_app/services/ixc_api_service.dart';
import 'package:sempre_online_app/pages/cadastro_senha_page.dart';

class LoginPage extends StatefulWidget {
  final String? savedCpf;
  final VoidCallback? onLoginSuccess;

  const LoginPage({Key? key, this.savedCpf, this.onLoginSuccess})
    : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _cpfCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  Map<String, dynamic>? _clienteCarregado;
  bool _loading = false;
  bool _rememberMe = false;
  bool _cpfValidado = false;
  String? _erro;
  Timer? _sessionTimer;

  @override
  void initState() {
    super.initState();
    // pré-preenche CPF salvo
    final saved = widget.savedCpf ?? AuthService().savedCpf;
    if (saved != null) {
      _cpfCtrl.text = saved;
      _rememberMe = true;
    }
  }

  @override
  void dispose() {
    _cpfCtrl.dispose();
    _senhaCtrl.dispose();
    _sessionTimer?.cancel();
    super.dispose();
  }

  Future<void> _verificarCpf() async {
    final cpf = _cpfCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (cpf.length != 11) {
      setState(() => _erro = 'CPF inválido.');
      return;
    }
    setState(() {
      _loading = true;
      _erro = null;
    });

    try {
      final cliente = await buscarClienteConfiavel(cpf);
      if (cliente == null) {
        setState(() => _erro = 'CPF não encontrado.');
      } else {
        final login = (cliente['hotsite_email'] ?? '').toString().trim();
        final senha = (cliente['senha'] ?? '').toString().trim();

        if (login.isEmpty || senha.isEmpty) {
          // primeiro acesso → cadastro de senha
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CadastroSenhaPage(cpf: cpf, cliente: cliente),
            ),
          );
          return;
        }

        _clienteCarregado = cliente;
        setState(() => _cpfValidado = true);
      }
    } catch (_) {
      setState(() => _erro = 'Erro ao buscar cliente.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _realizarLogin() async {
    final cpf = _cpfCtrl.text.replaceAll(RegExp(r'\D'), '');
    final senhaDigitada = _senhaCtrl.text.trim();

    if (senhaDigitada.length < 4) {
      setState(() => _erro = 'Senha inválida.');
      return;
    }
    if (_clienteCarregado == null) {
      setState(() => _erro = 'Reinicie e verifique o CPF.');
      return;
    }

    setState(() => _loading = true);

    final senhaIXC = (_clienteCarregado!['senha'] ?? '').toString().trim();
    if (senhaIXC != senhaDigitada) {
      setState(() {
        _erro = 'Senha incorreta.';
        _loading = false;
      });
      return;
    }

    final ok = await AuthService().login(
      cpf,
      senhaDigitada,
      remember: _rememberMe,
    );

    setState(() => _loading = false);

    if (ok) {
      _startSessionTimer();
      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!();
      } else {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } else {
      setState(() => _erro = 'Erro ao iniciar sessão.');
    }
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(const Duration(minutes: 30), () {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage('https://i.imgur.com/tnHuvUQ.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(.4)),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.08),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(.2)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          size: 68,
                          color: Colors.white70,
                        ),
                        const SizedBox(height: 16),
                        _GlassTextField(
                          controller: _cpfCtrl,
                          hint: 'CPF',
                          icon: Icons.person_outline,
                          keyboard: TextInputType.number,
                          inputFormatters: [_cpfMask],
                          enabled: !_cpfValidado,
                        ),
                        if (_cpfValidado) ...[
                          const SizedBox(height: 14),
                          _GlassTextField(
                            controller: _senhaCtrl,
                            hint: 'Senha',
                            icon: Icons.lock_outline,
                            obscure: true,
                          ),
                        ],
                        const SizedBox(height: 12),
                        if (_cpfValidado)
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged:
                                    (v) => setState(() => _rememberMe = v!),
                              ),
                              const Expanded(
                                child: Text(
                                  'Lembrar meu CPF neste dispositivo',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                        if (_erro != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _erro!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00B894),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed:
                                _loading
                                    ? null
                                    : (_cpfValidado
                                        ? _realizarLogin
                                        : _verificarCpf),
                            child:
                                _loading
                                    ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : Text(
                                      _cpfValidado ? 'ENTRAR' : 'CONTINUAR',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Use o CPF cadastrado como login.\n'
                          'A senha será criada se for seu primeiro acesso.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboard;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;

  const _GlassTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboard,
    this.inputFormatters,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      enabled: enabled,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(.15),
        prefixIcon: Icon(icon, color: Colors.white70),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

final _cpfMask = TextInputFormatter.withFunction((oldVal, newVal) {
  var d = newVal.text.replaceAll(RegExp(r'\D'), '');
  if (d.length > 11) d = d.substring(0, 11);
  final buf = StringBuffer();
  for (var i = 0; i < d.length; i++) {
    buf.write(d[i]);
    if (i == 2 || i == 5) buf.write('.');
    if (i == 8) buf.write('-');
  }
  return TextEditingValue(
    text: buf.toString(),
    selection: TextSelection.collapsed(offset: buf.length),
  );
});
