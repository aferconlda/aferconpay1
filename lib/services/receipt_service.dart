
import 'package:afercon_pay/models/transaction_model.dart'; // IMPORTAÇÃO ADICIONADA
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';


class ReceiptService {
    
    // Gera e exibe um PDF para uma dada transação
    static Future<void> generateAndShowReceipt(TransactionModel transaction) async {
        final pdf = pw.Document();
        
        // Adiciona uma página ao documento PDF
        pdf.addPage(
            pw.Page(
                pageFormat: PdfPageFormat.a4,
                build: (pw.Context context) {
                    return pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                            // 1. Cabeçalho
                            _buildHeader(),
                            pw.SizedBox(height: 20),
                            
                            // 2. Título do Documento
                            pw.Text(
                                'Comprovativo de Transação',
                                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Divider(thickness: 2),
                            pw.SizedBox(height: 20),
                            
                            // 3. Detalhes da Transação
                            _buildDetailRow('ID da Transação:', transaction.id),
                            _buildDetailRow('Data e Hora:', DateFormat('dd/MM/yyyy HH:mm').format(transaction.date)),
                            _buildDetailRow('Descrição:', transaction.description),
                            _buildDetailRow('Tipo de Transação:', _formatTransactionType(transaction.type)),
                            
                            pw.SizedBox(height: 30),
                            
                            // 4. Montante Total
                            _buildTotalAmount(transaction.amount),
                            
                            pw.Spacer(),
                            
                            // 5. Rodapé
                            _buildFooter(),
                        ],
                    );
                },
            ),
        );

        // Usa a biblioteca 'printing' para exibir a UI de impressão/partilha
        await Printing.layoutPdf(
            onLayout: (PdfPageFormat format) async => pdf.save(),
        );
    }

    // Widget para o cabeçalho do recibo
    static pw.Widget _buildHeader() {
        return pw.Container(
            alignment: pw.Alignment.center,
            child: pw.Text(
                'AferconPay',
                style: pw.TextStyle(
                    fontSize: 40,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey800,
                ),
            ),
        );
    }
    
    // Widget para uma linha de detalhe (ex: "ID: 123")
    static pw.Widget _buildDetailRow(String title, String value) {
        return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                    pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(value),
                ],
            ),
        );
    }

    // Widget para o montante total, destacado
    static pw.Widget _buildTotalAmount(double amount) {
        return pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                    pw.Text(
                        'Valor',
                        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                        // --- CORREÇÃO AQUI ---
                        NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz').format(amount),
                        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.green700),
                    ),
                ],
            ),
        );
    }

    // Widget para o rodapé
    static pw.Widget _buildFooter() {
        return pw.Center(
            child: pw.Text(
                'Documento processado via AferconPay - ${DateFormat('yyyy').format(DateTime.now())}',
                style: const pw.TextStyle(color: PdfColors.grey),
            ),
        );
    }
    
    // Função auxiliar para formatar o tipo de transação para uma leitura mais fácil
    static String _formatTransactionType(String type) {
        switch (type) {
            case 'revenue':
                return 'Receita (Entrada)';
            case 'expense':
                return 'Despesa (Saída)';
            case 'transfer_sent':
                return 'Transferência Enviada';
            case 'transfer_received':
                return 'Transferência Recebida';
            case 'credit_approved':
                return 'Crédito Aprovado';
            case 'withdrawal':
                 return 'Levantamento';
            default:
                return type;
        }
    }
}
