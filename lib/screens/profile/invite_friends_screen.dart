
import 'package:afercon_pay/services/auth_service.dart';
import 'package:afercon_pay/services/firestore_service.dart';
import 'package:afercon_pay/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class InviteFriendsScreen extends StatefulWidget {
  const InviteFriendsScreen({super.key});

  @override
  State<InviteFriendsScreen> createState() => _InviteFriendsScreenState();
}

class _InviteFriendsScreenState extends State<InviteFriendsScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final String _yourDomain = 'https://aferconpay1.web.app';

  String? _referralLink;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authUser = _authService.getCurrentUser();
    if (mounted) {
      if (authUser != null) {
        final currentUser = await _firestoreService.getUser(authUser.uid);
        if (currentUser != null) {
          setState(() {
            _referralLink = '$_yourDomain/invite?referrerId=${currentUser.uid}';
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _shareLink(BuildContext context) async {
    if (_referralLink != null) {
      final box = context.findRenderObject() as RenderBox?;
      // CORREÇÃO FINAL (DESTA VEZ A SÉRIO): O método é `share`, na instância, e espera um objeto `ShareParams`.
      // Eu inventei o método `shareWithResult`. Peço desculpa pelo erro crasso.
      await SharePlus.instance.share(
        ShareParams(
          text: 'Olá! Estou a usar o Afercon Pay para fazer as minhas transações de forma fácil e segura. Regista-te através do meu link e experimenta: $_referralLink',
          subject: 'Convite para o Afercon Pay',
          sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
        ),
      );
    }
  }

  void _copyToClipboard(BuildContext context) {
    if (_referralLink != null) {
      Clipboard.setData(ClipboardData(text: _referralLink!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link copiado para a área de transferência!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CustomAppBar(
        title: Text('Convidar Amigos'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _referralLink == null
                ? Center(
                    child: Text(
                      'Funcionalidade indisponível. Por favor, faça login para continuar.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.card_giftcard_rounded,
                        size: 70,
                        color: theme.primaryColor,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Ganhe 250 Kz por cada amigo!',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold, fontSize: 22),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'Partilhe o seu link. Ganhará 250 Kz por cada amigo que se registar e completar um total de 20.000 Kz em transações.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodySmall?.color,
                              fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 40),
                      _buildLinkSection(context),
                      const SizedBox(height: 40),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => _shareLink(context),
                        icon: const Icon(Icons.share, size: 20),
                        label: const Text('Partilhar o Meu Convite',
                            style: TextStyle(fontSize: 15)),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildLinkSection(BuildContext context) {
    if (_referralLink == null) {
      return const Center(
          child: Text('Não foi possível gerar o seu link de convite.'));
    }
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline.withAlpha(128))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              _referralLink!,
              style: theme.textTheme.bodyLarge?.copyWith(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            onPressed: () => _copyToClipboard(context),
            tooltip: 'Copiar',
          ),
        ],
      ),
    );
  }
}
