import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  // Chave para guardar a preferência no dispositivo
  static const String _kThemeModeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system; // Começa com o tema do sistema
  ThemeMode get themeMode => _themeMode;

  // Construtor que carrega a preferência salva ao iniciar
  ThemeProvider() {
    _loadTheme();
  }

  // Carrega o tema salvo no dispositivo
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_kThemeModeKey);

    if (savedTheme != null) {
      _themeMode = _getThemeModeFromString(savedTheme);
    }
    // Notifica os 'ouvintes' (a UI) sobre o tema carregado
    notifyListeners();
  }

  // Alterna entre o modo claro e escuro e salva a escolha
  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await _saveTheme();
    notifyListeners();
  }

  // Define um tema específico e salva a escolha
  Future<void> setTheme(ThemeMode themeMode) async {
    if (_themeMode == themeMode) return;
    _themeMode = themeMode;
    await _saveTheme();
    notifyListeners();
  }

  // Salva a preferência atual no dispositivo
  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeModeKey, _themeMode.name);
  }

  // Função auxiliar para converter a String salva de volta para um ThemeMode
  ThemeMode _getThemeModeFromString(String themeString) {
    switch (themeString) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }
}
