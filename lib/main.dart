// lib/main.dart

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:sempre_online_app/services/auth_service.dart';
import 'package:sempre_online_app/pages/login_page.dart';
import 'package:sempre_online_app/home_controller.dart';

Future<void> main() async {
  // Garante que tudo do Flutter esteja inicializado antes de usarmos plugins async
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa os dados de formatação de data para pt_BR
  await initializeDateFormatting('pt_BR', null);
  Intl.defaultLocale = 'pt_BR';

  // Carrega sessão e dados locais (token, usuário salvo, etc.)
  await AuthService().initialize();

  runApp(const MeuApp());
}

class MeuApp extends StatefulWidget {
  const MeuApp({Key? key}) : super(key: key);

  @override
  State<MeuApp> createState() => _MeuAppState();
}

class _MeuAppState extends State<MeuApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sempre Online',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF00B894),
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true),
      initialRoute: AuthService().isLoggedIn ? '/home' : '/',
      routes: {
        '/':
            (ctx) => LoginPage(
              onLoginSuccess:
                  () => Navigator.of(ctx).pushReplacementNamed('/home'),
            ),
        '/home':
            (ctx) => HomeController(
              themeMode: _themeMode,
              onToggleTheme: _toggleTheme,
            ),
      },
    );
  }
}
