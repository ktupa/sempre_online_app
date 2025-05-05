// lib/services/speed_test_service.dart

import 'package:speed_test_dart/speed_test_dart.dart';

class SpeedTestService {
  final SpeedTestDart _tester = SpeedTestDart();

  /// Executa o teste de velocidade usando speedtest.net via speed_test_dart
  Future<Map<String, double>> testarVelocidadeAPI() async {
    // 1) obtém configurações, incluindo lista de servidores
    final settings = await _tester.getSettings();
    final servers = settings.servers;

    // 2) roda o download (retorna MB/s)
    final downloadMBps = await _tester.testDownloadSpeed(servers: servers);

    // 3) roda o upload (retorna MB/s)
    final uploadMBps = await _tester.testUploadSpeed(servers: servers);

    // 4) converte MB/s → Mb/s (multiplica por 8) e retorna
    return {'download': downloadMBps * 8, 'upload': uploadMBps * 8};
  }
}
