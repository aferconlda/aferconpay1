
import 'package:afercon_pay/screens/qr_code/receive_qr_screen.dart';
import 'package:afercon_pay/screens/qr_code/scan_qr_screen.dart';
import 'package:afercon_pay/screens/referral/referral_screen.dart';
import 'package:afercon_pay/screens/transactions/deposit_screen.dart';
import 'package:afercon_pay/screens/transactions/transfer_screen.dart';
import 'package:afercon_pay/screens/transactions/withdraw_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ActionButtonsGrid extends StatelessWidget {
  const ActionButtonsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12.h,
      crossAxisSpacing: 12.w,
      childAspectRatio: 1.1,
      children: [
        _buildActionButton(context,
            icon: Icons.send_outlined,
            label: 'Transferir',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const TransferScreen()))),
        _buildActionButton(context,
            icon: Icons.arrow_downward_outlined,
            label: 'Depositar',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const DepositScreen()))),
        _buildActionButton(context,
            icon: Icons.arrow_upward_outlined,
            label: 'Levantar',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const WithdrawScreen()))),
        _buildActionButton(context,
            icon: Icons.qr_code_scanner,
            label: 'Pagar com QR',
            // CORRECTED: Simplified navigation directly to the scanner screen
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ScanQrScreen()))),
        _buildActionButton(context,
            icon: Icons.qr_code_2,
            label: 'Receber QR',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const ReceiveQrScreen()))),
        _buildActionButton(context,
            icon: Icons.person_add_outlined,
            label: 'Convidar',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const ReferralScreen()))),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context,
      {required IconData icon, required String label, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  )
                ]),
            child: Icon(icon, size: 28.sp, color: theme.colorScheme.primary),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w600, fontSize: 11.sp),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
