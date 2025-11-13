import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // --------------------------------------------------
  // DEFINIÇÃO DAS CORES
  // --------------------------------------------------

  static const Color primaryColor = Color(0xFF4CAF50);
  static const Color secondaryColor = Color(0xFF2196F3);

  static const Color _lightGrey = Color(0xFFF5F5F5);
  static const Color _mediumGrey = Color(0xFFBDBDBD);
  static const Color _darkGrey = Color(0xFF424242);
  static const Color _darkerGrey = Color(0xFF212121);
  static const Color _almostBlack = Color(0xFF121212); // Cor de fundo padrão do Material Design para modo escuro
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _black = Color(0xFF000000);

  // --------------------------------------------------
  // GETTER PARA O TEMA CLARO
  // --------------------------------------------------
  static ThemeData get lightTheme {
    final baseTheme = ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: _lightGrey,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: _white,
        onPrimary: _white,
        onSecondary: _white,
        onSurface: _black,
        error: Colors.redAccent,
        onError: _white,
      ),
      appBarTheme: _appBarTheme(isDark: false),
      elevatedButtonTheme: _elevatedButtonTheme(),
      inputDecorationTheme: _inputDecorationTheme(isDark: false),
      cardTheme: _cardTheme(isDark: false),
      dialogTheme: _dialogTheme(isDark: false),
      dividerTheme: _dividerTheme(isDark: false),
      bottomNavigationBarTheme: _bottomNavigationBarTheme(isDark: false),
    );
    return baseTheme.copyWith(
      textTheme: GoogleFonts.latoTextTheme(baseTheme.textTheme).apply(bodyColor: _black, displayColor: _black),
    );
  }

  // --------------------------------------------------
  // GETTER PARA O TEMA ESCURO (CORRIGIDO)
  // --------------------------------------------------
  static ThemeData get darkTheme {
     final baseTheme = ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: _almostBlack, 
      visualDensity: VisualDensity.adaptivePlatformDensity,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: _darkerGrey,
        onPrimary: _white,
        onSecondary: _white,
        onSurface: _white,
        error: Colors.redAccent,
        onError: _white,
      ),
      appBarTheme: _appBarTheme(isDark: true),
      elevatedButtonTheme: _elevatedButtonTheme(),
      inputDecorationTheme: _inputDecorationTheme(isDark: true),
      cardTheme: _cardTheme(isDark: true),
      dialogTheme: _dialogTheme(isDark: true),
      dividerTheme: _dividerTheme(isDark: true),
      iconTheme: const IconThemeData(color: _white),
      bottomNavigationBarTheme: _bottomNavigationBarTheme(isDark: true),
    );
     return baseTheme.copyWith(
      textTheme: GoogleFonts.latoTextTheme(baseTheme.textTheme).apply(bodyColor: _white, displayColor: _white),
    );
  }

  // --------------------------------------------------
  // MÉTODOS PRIVADOS PARA COMPONENTES
  // --------------------------------------------------

  static AppBarTheme _appBarTheme({required bool isDark}) {
    return AppBarTheme(
      backgroundColor: isDark ? _darkerGrey : primaryColor, 
      elevation: 0,
      iconTheme: const IconThemeData(color: _white),
      titleTextStyle: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.w600, color: _white),
    );
  }
  
  static BottomNavigationBarThemeData _bottomNavigationBarTheme({required bool isDark}) {
    return BottomNavigationBarThemeData(
      backgroundColor: isDark ? _darkerGrey : _white,
      selectedItemColor: primaryColor,
      unselectedItemColor: _mediumGrey,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: _white,
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
        textStyle: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static InputDecorationTheme _inputDecorationTheme({required bool isDark}) {
    return InputDecorationTheme(
      filled: true,
      fillColor: isDark ? _darkGrey : _white,
      hintStyle: TextStyle(color: isDark ? _mediumGrey : _darkGrey),
      prefixIconColor: isDark ? _white : _darkGrey,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? _mediumGrey.withAlpha(128) : _mediumGrey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      labelStyle: TextStyle(color: isDark ? _lightGrey : _darkGrey),
    );
  }

  static CardThemeData _cardTheme({required bool isDark}) {
    return CardThemeData(
      clipBehavior: Clip.antiAlias,
      color: isDark ? _darkerGrey : _white,
      elevation: isDark ? 1 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: isDark ? BorderSide(color: Colors.grey.withAlpha(51)) : BorderSide.none, 
      ),
    );
  }

  static DialogThemeData _dialogTheme({required bool isDark}) {
    return DialogThemeData(
      backgroundColor: isDark ? _darkerGrey : _white,
      titleTextStyle: GoogleFonts.lato(color: isDark ? _white : _darkGrey, fontSize: 20, fontWeight: FontWeight.bold),
      contentTextStyle: GoogleFonts.lato(color: isDark ? _lightGrey : _darkGrey),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
    );
  }

  static DividerThemeData _dividerTheme({required bool isDark}) {
    return DividerThemeData(
      color: isDark ? _mediumGrey.withAlpha(128) : _mediumGrey,
      thickness: 1,
      space: 24,
    );
  }
}
