
import 'dart:convert';

class QrCodeParser {
  final String qrCodeData;

  QrCodeParser(this.qrCodeData);

  Future<Map<String, dynamic>> parse() async {
    try {
      final decodedData = jsonDecode(qrCodeData);

      if (decodedData is! Map<String, dynamic>) {
        throw const FormatException('O código QR não contém dados válidos.');
      }

      final uid = decodedData['uid'] as String?;
      final amount = decodedData['amount'] as double?;
      final type = decodedData['type'] as String?;

      if (uid == null || uid.isEmpty) {
        throw const FormatException('O código QR não contém um identificador de utilizador válido.');
      }

      return {
        'uid': uid,
        'amount': amount,
        'type': type ?? 'payment',
      };
    } on FormatException catch (e) {
      // Re-throw with a more user-friendly message
      throw FormatException('Formato de código QR inválido: ${e.message}');
    } catch (e) {
      // Catch any other unexpected errors during parsing
      throw Exception('Ocorreu um erro ao ler o código QR. Tente novamente.');
    }
  }
}
