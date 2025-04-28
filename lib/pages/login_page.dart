// lib/pages/login_page.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sempre_online_app/services/auth_service.dart';

enum LoginTipo { cpf, email }

class LoginPage extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  const LoginPage({Key? key, this.onLoginSuccess}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  LoginTipo _loginTipo = LoginTipo.cpf;
  final _ctrlLogin = TextEditingController();
  final _ctrlSenha = TextEditingController();
  bool _loading = false;
  bool _rememberMe = false; // ← controla o checkbox
  String? _errorMessage;
  Timer? _sessionTimer;

  @override
  void initState() {
    super.initState();
    // Usa o getter público savedCpf
    final savedCpf = AuthService().savedCpf; // ✅ getter público
    if (savedCpf != null) {
      _ctrlLogin.text = savedCpf;
      _rememberMe = true;
    }
  }

  @override
  void dispose() {
    _ctrlLogin.dispose();
    _ctrlSenha.dispose();
    _sessionTimer?.cancel();
    super.dispose();
  }

  Future<void> _login() async {
    final loginInput = _ctrlLogin.text.trim();
    if (loginInput.isEmpty) {
      setState(() => _errorMessage = 'Preencha seu CPF ou E-mail.');
      return;
    }
    if (_loginTipo == LoginTipo.cpf &&
        loginInput.replaceAll(RegExp(r'\D'), '').length != 11) {
      setState(() => _errorMessage = 'CPF inválido.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // Usa AuthService para login e lembrar ou não
      final ok = await AuthService().login(loginInput, remember: _rememberMe);
      if (ok) {
        _startSessionTimer();
        widget.onLoginSuccess?.call();
      } else {
        setState(() => _errorMessage = 'Usuário não encontrado.');
      }
    } catch (_) {
      setState(() => _errorMessage = 'Erro de conexão.');
    } finally {
      if (mounted) setState(() => _loading = false);
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
    final isCpf = _loginTipo == LoginTipo.cpf;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage('https://i.imgur.com/aEeIQjd.jpeg'),
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
                        ToggleButtons(
                          borderRadius: BorderRadius.circular(8),
                          isSelected: [
                            _loginTipo == LoginTipo.cpf,
                            _loginTipo == LoginTipo.email,
                          ],
                          selectedColor: Colors.white,
                          fillColor: const Color(0xFF00B894),
                          color: Colors.white70,
                          constraints: const BoxConstraints(
                            minHeight: 32,
                            minWidth: 100,
                          ),
                          onPressed: (i) {
                            setState(() {
                              _loginTipo = LoginTipo.values[i];
                              _ctrlLogin.clear();
                              _ctrlSenha.clear();
                              _errorMessage = null;
                            });
                          },
                          children: const [Text('CPF'), Text('E-mail')],
                        ),
                        const SizedBox(height: 20),
                        _GlassTextField(
                          controller: _ctrlLogin,
                          hint: isCpf ? '000.000.000-00' : 'seu@email',
                          icon: Icons.person_outline,
                          keyboard:
                              isCpf
                                  ? TextInputType.number
                                  : TextInputType.emailAddress,
                          inputFormatters: isCpf ? [_cpfMask] : null,
                        ),
                        if (!isCpf) ...[
                          const SizedBox(height: 14),
                          _GlassTextField(
                            controller: _ctrlSenha,
                            hint: 'Senha',
                            icon: Icons.lock_outline,
                            obscure: true,
                          ),
                        ],
                        const SizedBox(height: 12),
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
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
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
                            onPressed: _loading ? null : _login,
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
                                    : const Text(
                                      'ENTRAR',
                                      style: TextStyle(fontSize: 16),
                                    ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Entre com seu CPF ou e-mail\ncadastrado junto ao provedor.',
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

  const _GlassTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboard,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
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
  final out = buf.toString();
  return TextEditingValue(
    text: out,
    selection: TextSelection.collapsed(offset: out.length),
  );
});
