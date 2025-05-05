import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
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

  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic>? get clientData => _clientData;
  String? get savedCpf => _savedCpf;

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

  Future<bool> login(String cpf, String senha, {bool remember = false}) async {
    final cliente = await buscarClienteConfiavel(cpf);
    if (cliente == null) return false;

    final senhaReal = (cliente['senha'] ?? '').toString().trim();
    final cpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');

    if (senhaReal != senha) return false;

    _clientData = cliente;
    _isLoggedIn = true;
    _savedCpf = cpfLimpo;
    _startSessionTimer();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('session_active', true);

    if (remember) {
      await prefs.setBool('remember_login', true);
      await prefs.setString('saved_cpf', cpfLimpo);
      await prefs.setString('client_data', jsonEncode(cliente));
    } else {
      await prefs.remove('remember_login');
      await prefs.remove('saved_cpf');
      await prefs.remove('client_data');
    }

    // 🔔 Envia token FCM
    final fcmToken = await FirebaseMessaging.instance.getToken();
    final idCliente = cliente['id']?.toString() ?? '';

    if (fcmToken != null && idCliente.isNotEmpty) {
      await _enviarTokenParaBackend(fcmToken, idCliente);
    }

    return true;
  }

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

    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(const Duration(minutes: 30), () {
      _isLoggedIn = false;
    });
  }

  Future<void> _enviarTokenParaBackend(String token, String idCliente) async {
    final url = Uri.parse('http://138.117.249.70:8087/fcm/token');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token, 'id_cliente': idCliente}),
    );

    if (res.statusCode == 200) {
      debugPrint('✅ Token FCM enviado com sucesso.');
    } else {
      debugPrint('❌ Erro ao enviar token FCM: ${res.statusCode} → ${res.body}');
    }
  }
}
