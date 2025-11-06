import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReferralService {
  // LÓGICA ATUALIZADA: Chaves alteradas para corresponder ao link gerado
  static const String _refParamKey = 'ref';
  static const String _refPath = '/join';
  
  static const String _prefsKey = 'referrerId'; // Chave para SharedPreferences pode manter-se

  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  ReferralService._privateConstructor() {
    _appLinks = AppLinks();
  }

  static final ReferralService _instance = ReferralService._privateConstructor();

  factory ReferralService() {
    return _instance;
  }

  Future<void> init() async {
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      // LÓGICA ATUALIZADA: Verifica o path e o parâmetro corretos
      if (uri.path == _refPath && uri.queryParameters.containsKey(_refParamKey)) {
        final referrerId = uri.queryParameters[_refParamKey];
        if (referrerId != null && referrerId.isNotEmpty) {
          _saveReferrerId(referrerId);
        }
      }
    });

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        // LÓGICA ATUALIZADA: Verifica o path e o parâmetro corretos no link inicial
        if (initialUri.path == _refPath && initialUri.queryParameters.containsKey(_refParamKey)) {
          final referrerId = initialUri.queryParameters[_refParamKey];
          if (referrerId != null && referrerId.isNotEmpty) {
            _saveReferrerId(referrerId);
          }
        }
      }
    } on Exception {
      // Não conseguiu obter o link inicial, pode ser ignorado.
    }
  }

  Future<void> _saveReferrerId(String referrerId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, referrerId);
  }

  Future<String?> getAndClearReferrerId() async {
    final prefs = await SharedPreferences.getInstance();
    final referrerId = prefs.getString(_prefsKey);
    if (referrerId != null) {
      await prefs.remove(_prefsKey);
    }
    return referrerId;
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
