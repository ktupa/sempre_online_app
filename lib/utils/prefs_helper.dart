import 'package:shared_preferences/shared_preferences.dart';

/// Helper centralizado para lidar com `SharedPreferences`
/// (contrato padrão exibido no Dashboard).
///
/// Mantém apenas **o id do contrato** escolhido pelo usuário.
/// Caso o usuário ainda não tenha feito uma escolha, o método `getContratoPreferido()`
/// retorna `null`.
class PrefsHelper {
  static const _kContratoKey = 'contrato_preferido';

  /// Salva o id do contrato escolhido.
  static Future<void> setContratoPreferido(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kContratoKey, id);
  }

  /// Recupera o id salvo ou `null` se o usuário nunca escolheu.
  static Future<String?> getContratoPreferido() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kContratoKey);
  }
}
