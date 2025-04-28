import 'package:flutter/material.dart';
import 'package:sempre_online_app/services/auth_service.dart';
import 'package:sempre_online_app/pages/dashboard_page.dart';
import 'package:sempre_online_app/pages/connection_tab.dart';
import 'package:sempre_online_app/pages/contracts_tab.dart';
import 'package:sempre_online_app/pages/faturas_page.dart';
import 'package:sempre_online_app/pages/chamados_page.dart';
import 'package:sempre_online_app/pages/perfil_page.dart';

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

class _HomeControllerState extends State<HomeController> {
  late int _selectedIndex;
  late final String _cpf;
  late final String _clienteId;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;

    final data = AuthService().clientData!;
    _cpf = data['cnpj_cpf'] as String;
    _clienteId = data['id'] as String;

    _pages = [
      DashboardPage(
        onNavigateTab: _onNavigateTab,
      ), // Passa callback para Dashboard
      ConnectionTab(cpf: _cpf, clientId: _clienteId),
      ContractsTab(cpf: _cpf, clientId: _clienteId),
      FaturasPage(clientId: _clienteId),
      const ChamadosPage(),
      const PerfilPage(),
    ];
  }

  void _onNavigateTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  IconData get _themeIcon =>
      widget.themeMode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode;

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
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => AuthService().logout(context),
          ),
          IconButton(
            icon: Icon(_themeIcon),
            tooltip: 'Mudar Tema',
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        selectedItemColor: cs.primary,
        unselectedItemColor: cs.onSurface.withOpacity(.6),
        backgroundColor: cs.surface,
        showSelectedLabels: false,
        showUnselectedLabels: false,
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
