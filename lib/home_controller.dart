// lib/pages/home_controller.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import 'package:sempre_online_app/services/auth_service.dart';
import 'package:sempre_online_app/services/ixc_api_service.dart';

import 'package:sempre_online_app/pages/dashboard_page.dart';
import 'package:sempre_online_app/pages/connection_tab.dart';
import 'package:sempre_online_app/pages/contracts_tab.dart';
import 'package:sempre_online_app/pages/faturas_page.dart';
import 'package:sempre_online_app/pages/chamados_page.dart';
import 'package:sempre_online_app/pages/perfil_page.dart';
import 'package:sempre_online_app/widgets/notificacao_modal.dart';

/* ---------- contrato salvo ---------- */
class _Prefs {
  static const _kContrato = 'contrato_pref';
  static const _kNotifLida = 'notificacao_lida';

  static Future<String?> getContrato() async =>
      (await SharedPreferences.getInstance()).getString(_kContrato);

  static Future<bool> isNotifLida() async =>
      (await SharedPreferences.getInstance()).getBool(_kNotifLida) ?? false;

  static Future<void> marcarNotifComoLida() async =>
      (await SharedPreferences.getInstance()).setBool(_kNotifLida, true);
}

/* ======================================================================= */
class HomeController extends StatefulWidget {
  final int initialIndex;
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  const HomeController({
    Key? key,
    this.initialIndex = 0,
    required this.themeMode,
    required this.onToggleTheme,
  }) : super(key: key);

  @override
  State<HomeController> createState() => _HomeControllerState();
}

/* ======================================================================= */
class _HomeControllerState extends State<HomeController> {
  late final String _cpf;
  late final String _clienteId;
  late final List<Widget> _pages;

  int _selectedIndex = 0;
  int _badgeFaturas = 0;
  int _badgeChamados = 0;
  bool _notificacaoNaoLida = true;
  String? _contratoRef;

  @override
  void initState() {
    super.initState();
    final u = AuthService().clientData!;
    _cpf = u['cnpj_cpf'];
    _clienteId = u['id'].toString();
    _selectedIndex = widget.initialIndex;

    _pages = [
      DashboardPage(onNavigateTab: _onNavigateTab),
      ConnectionTab(cpf: _cpf, clientId: _clienteId),
      ContractsTab(
        cpf: _cpf,
        clientId: _clienteId,
        onNavigateTab: _onNavigateTab,
      ),
      FaturasPage(clientId: _clienteId),
      const ChamadosPage(),
      const PerfilPage(),
    ];

    _syncAlerts();
  }

  Future<int> _countFaturasVencidas() async {
    final all = await listarFaturasDoCliente(_clienteId);
    final today = DateTime.now();

    int total = 0;
    for (final f in all) {
      if ((f['status'] ?? '').toString().toUpperCase() == 'B') continue;
      if (_contratoRef != null && f['id_contrato']?.toString() != _contratoRef)
        continue;

      final venc = f['data_vencimento'] ?? '';
      try {
        final dt = DateFormat('yyyy-MM-dd').parse(venc);
        if (dt.isBefore(today)) total++;
      } catch (_) {}
    }
    return total;
  }

  Future<int> _countChamadosAbertos() async {
    final all = await listarChamadosCliente(_clienteId);
    return all
        .where((c) => (c['status'] ?? '').toString().toUpperCase() == 'A')
        .length;
  }

  Future<void> _syncAlerts() async {
    _contratoRef = await _Prefs.getContrato();
    final fats = await _countFaturasVencidas();
    final tickets = await _countChamadosAbertos();
    final notifLida = await _Prefs.isNotifLida();

    if (mounted) {
      setState(() {
        _badgeFaturas = fats;
        _badgeChamados = tickets;
        _notificacaoNaoLida = !notifLida;
      });
    }
  }

  void _onNavigateTab(int index) => setState(() => _selectedIndex = index);

  IconData get _themeIcon =>
      widget.themeMode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode;

  Widget _badge(int v, Color color) =>
      v == 0
          ? const SizedBox.shrink()
          : Positioned(
            right: 0,
            top: 7,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$v',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );

  void _abrirNotificacoes() async {
    await showDialog(
      context: context,
      builder: (_) => const NotificacaoModal(),
    );
    await _Prefs.marcarNotifComoLida();
    setState(() => _notificacaoNaoLida = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.primary,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: Icon(Icons.wifi, size: 28),
        ),
        title: const Text('Sempre Online'),
        actions: [
          /* ---- Notificações do sistema (modal) ---- */
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _abrirNotificacoes,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.notifications_rounded, size: 26),
                  if (_notificacaoNaoLida) _badge(1, Colors.blue.shade700),
                ],
              ),
            ),
          ),

          /* ---- Faturas vencidas ---- */
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() => _selectedIndex = 3),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.receipt_long_rounded, size: 26),
                  _badge(_badgeFaturas, Colors.red.shade700),
                ],
              ),
            ),
          ),

          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => AuthService().logout(context),
          ),
          IconButton(
            icon: Icon(_themeIcon),
            tooltip: 'Mudar tema',
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) async {
          setState(() => _selectedIndex = i);
          await _syncAlerts();
        },
        selectedItemColor: cs.primary,
        unselectedItemColor: cs.onSurface.withOpacity(.6),
        backgroundColor: cs.surface,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.wifi), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.support_agent), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
      ),
    );
  }
}
