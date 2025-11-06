import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart'; // Adicionado para o efeito de loading

class BalanceCard extends StatefulWidget {
  final double balance;
  final NumberFormat format;
  final bool isLoading; // Nova propriedade

  const BalanceCard({
    super.key, 
    required this.balance, 
    required this.format,
    this.isLoading = false, // Valor padrão é false
  });

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
  bool _isBalanceVisible = true;

  void _toggleVisibility() {
    setState(() {
      _isBalanceVisible = !_isBalanceVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Se estiver a carregar, mostra o esqueleto com Shimmer
    if (widget.isLoading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: _buildCardContent(context, theme, true), // `isSkeleton = true`
      );
    }

    // Caso contrário, mostra o conteúdo normal
    return _buildCardContent(context, theme, false);
  }

  Widget _buildCardContent(BuildContext context, ThemeData theme, bool isSkeleton) {
    return Card(
      clipBehavior: Clip.antiAlias, // Garante que o gradiente respeita as bordas
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          gradient: isSkeleton
            ? null // Sem gradiente no esqueleto
            : LinearGradient(
                colors: [theme.primaryColor, theme.colorScheme.secondary.withAlpha(204)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
          color: isSkeleton ? Colors.white : null, // Fundo branco para o esqueleto
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Texto 'SALDO ATUAL' ou um placeholder
                isSkeleton
                  ? Container(width: 100.w, height: 16.h, color: Colors.white)
                  : Text(
                      'SALDO ATUAL',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withAlpha(204), letterSpacing: 1.5.w),
                    ),
                // Ícone de visibilidade ou um placeholder
                isSkeleton
                  ? const SizedBox.shrink()
                  : IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        _isBalanceVisible ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white.withAlpha(204),
                      ),
                      onPressed: _toggleVisibility,
                    ),
              ],
            ),
            SizedBox(height: 8.h),
            // Saldo ou um placeholder maior
            isSkeleton
              ? Container(width: 200.w, height: 40.h, color: Colors.white)
              : Text(
                  _isBalanceVisible ? widget.format.format(widget.balance) : '******',
                  style: theme.textTheme.headlineLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
          ],
        ),
      ),
    );
  }
}
