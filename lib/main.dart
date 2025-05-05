import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:sempre_online_app/services/auth_service.dart';
import 'package:sempre_online_app/pages/login_page.dart';
import 'package:sempre_online_app/home_controller.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firebase_options.dart'; // gerado pelo `flutterfire configure`

/// Plugin de notificações locais
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Handler para mensagens recebidas em background
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  _showNotification(message);
}

/// Exibe a notificação local
void _showNotification(RemoteMessage message) {
  final n = message.notification;
  if (n == null) return;

  flutterLocalNotificationsPlugin.show(
    n.hashCode,
    n.title,
    n.body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'sempre_online_channel', // canal criado abaixo
        'Notificações Sempre Online',
        channelDescription: 'Alertas de fatura, manutenção, etc.',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    ),
  );
}

/// Envia token + id_cliente para o backend
Future<void> enviarTokenParaBackend(String token, String idCliente) async {
  final url = Uri.parse('http://138.117.249.70:8087/fcm/token');
  final res = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'token': token, 'id_cliente': idCliente}),
  );

  if (res.statusCode == 200) {
    debugPrint('✅ Token FCM enviado com sucesso!');
  } else {
    debugPrint('❌ Erro ao enviar token FCM: ${res.statusCode} → ${res.body}');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // formatação de data para pt_BR
  await initializeDateFormatting('pt_BR', null);
  Intl.defaultLocale = 'pt_BR';

  // inicializa Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // configura canal Android
  const androidChannel = AndroidNotificationChannel(
    'sempre_online_channel',
    'Notificações Sempre Online',
    description: 'Alertas de fatura, manutenção, etc.',
    importance: Importance.max,
  );
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(androidChannel);

  // inicializa plugin de notificações locais
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(
    android: androidInit,
    iOS: DarwinInitializationSettings(),
  );
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // registra handlers do FCM
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  FirebaseMessaging.onMessage.listen(_showNotification);

  // solicita permissão (iOS / Android 13+)
  await FirebaseMessaging.instance.requestPermission();

  // inicializa sessão e recupera cliente salvo (se houver)
  await AuthService().initialize();

  // obtém token FCM e envia junto com id_cliente para o backend
  final fcmToken = await FirebaseMessaging.instance.getToken();
  final idCliente = AuthService().clientData?['id']?.toString().trim() ?? '';

  debugPrint('📲 TOKEN FCM: $fcmToken');
  debugPrint('👤 ID do cliente: $idCliente');

  if (fcmToken != null && idCliente.isNotEmpty) {
    await enviarTokenParaBackend(fcmToken, idCliente);
  }

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
