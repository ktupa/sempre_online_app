// lib/services/auth_service.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ixc_api_service.dart';

class AuthService {
  // Singleton
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  Timer? _sessionTimer;
  bool _isLoggedIn = false;
  Map<String, dynamic>? _clientData;
  String? _savedCpf;

  /// Indica se o usuário está logado
  bool get isLoggedIn => _isLoggedIn;

  /// Retorna os dados completos do cliente autenticado
  Map<String, dynamic>? get clientData => _clientData;

  /// Retorna o CPF salvo (para pré-preencher o campo)
  String? get savedCpf => _savedCpf;

  /// Deve ser chamado antes de runApp()
  /// Carrega sessão e dados salvos, se existirem e "lembrar" estiver ativo
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final active = prefs.getBool('session_active') ?? false;
    final remember = prefs.getBool('remember_login') ?? false;
    final cpf = prefs.getString('saved_cpf');
    final jsonStr = prefs.getString('client_data');

    if (active && remember && cpf != null && jsonStr != null) {
      _savedCpf = cpf;
      _clientData = jsonDecode(jsonStr) as Map<String, dynamic>?;
      _isLoggedIn = _clientData != null;
      if (_isLoggedIn) _startSessionTimer();
    }
  }

  /// Tenta autenticar pelo CPF (ou e-mail, se implementar depois)
  /// Se [remember]=true, salva CPF e dados em prefs para próximas execuções
  Future<bool> login(String cpf, {bool remember = false}) async {
    // 1) Verifica existência do CPF
    final exists = await autenticarClientePorCpf(cpf);
    if (!exists) return false;

    // 2) Busca dados completos do cliente
    final data = await buscarClientePorCpf(cpf);
    if (data == null) return false;

    // 3) Atualiza estado interno
    _clientData = data;
    _isLoggedIn = true;
    _savedCpf = cpf;
    _startSessionTimer();

    // 4) Persiste estado em SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('session_active', true);

    if (remember) {
      await prefs.setBool('remember_login', true);
      await prefs.setString('saved_cpf', cpf);
      await prefs.setString('client_data', jsonEncode(data));
    } else {
      await prefs.remove('remember_login');
      await prefs.remove('saved_cpf');
      await prefs.remove('client_data');
    }

    return true;
  }

  /// Encerra a sessão, limpa todos os dados salvos e retorna para a tela de login
  Future<void> logout(BuildContext context) async {
    _isLoggedIn = false;
    _clientData = null;
    _savedCpf = null;
    _sessionTimer?.cancel();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_active');
    await prefs.remove('remember_login');
    await prefs.remove('saved_cpf');
    await prefs.remove('client_data');

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(const Duration(minutes: 30), () {
      _isLoggedIn = false;
    });
  }
}
