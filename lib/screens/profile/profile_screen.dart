import 'package:afercon_pay/models/user_model.dart';
import 'package:afercon_pay/screens/admin/admin_dashboard_screen.dart';
import 'package:afercon_pay/screens/cashier/cashier_panel_screen.dart';
import 'package:afercon_pay/screens/kyc/kyc_verification_screen.dart';
import 'package:afercon_pay/screens/profile/change_pin_screen.dart';
import 'package:afercon_pay/screens/profile/privacy_policy_screen.dart';
import 'package:afercon_pay/screens/profile/terms_and_conditions_screen.dart';
import 'package:afercon_pay/screens/profile/notification_settings_screen.dart';
import 'package:afercon_pay/services/auth_service.dart';
import 'package:afercon_pay/services/firestore_service.dart';
import 'package:afercon_pay/theme/theme_provider.dart';
import 'package:afercon_pay/widgets/custom_app_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  
  UserModel? _currentUser;
  Stream<UserModel>? _userStream;
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
        final userModel = await _firestoreService.getUser(authUser.uid);
        setState(() {
          _currentUser = userModel;
          _userStream = _firestoreService.getUserStream(authUser.uid);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Terminar Sessão'),
          content: const Text('Tem a certeza de que deseja sair?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Sair'),
              onPressed: () {
                _authService.signOut();
                if (mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _refreshProfile() async {
    if (_currentUser != null) {
      setState(() {
        _userStream = _firestoreService.getUserStream(_currentUser!.uid);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        appBar: CustomAppBar(title: Text('Meu Perfil')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null || _userStream == null) {
      return Scaffold(
        appBar: const CustomAppBar(title: Text('Meu Perfil')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Não foi possível carregar o perfil. Por favor, inicie sessão novamente.'),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _showLogoutConfirmation, child: const Text('Iniciar Sessão'))
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(title: Text('Meu Perfil')),
      body: StreamBuilder<UserModel>(
        stream: _userStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Não foi possível carregar os dados do utilizador.'));
          }

          final userData = snapshot.data!;
          final kycStatus = userData.kycStatus;
          
          // Robust role check and logging
          final userRole = userData.role.toLowerCase();
          
          if (kDebugMode) {
            print('--- Profile Screen ---');
            print('User role from Firestore: $userRole');
          }
          
          final isAdmin = userRole == 'admin';
          final isCashier = userRole == 'cashier';

          if (kDebugMode) {
            print('isAdmin flag: $isAdmin');
            print('isCashier flag: $isCashier');
            print('--- End Profile Screen ---');
          }

          final isEmailVerified = userData.isEmailVerified;

          return RefreshIndicator(
            onRefresh: _refreshProfile,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              children: <Widget>[
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.person, size: 50, color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 12),
                      Text(userData.displayName ?? 'Anónimo', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(userData.email ?? 'Sem email', style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                _buildKycStatusCard(context, kycStatus.name),
                
                const SizedBox(height: 16),

                if (isAdmin)
                  Card(
                    elevation: 2,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: _buildProfileListTile(
                      context: context,
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'Painel de Administração',
                      isSpecial: true,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const AdminDashboardScreen(),
                      )),
                    ),
                  ),
                  
                if (isCashier)
                  Card(
                    elevation: 2,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: _buildProfileListTile(
                      context: context,
                      icon: Icons.qr_code_scanner,
                      title: 'Painel do Caixa',
                      isSpecial: true,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const CashierPanelScreen(),
                      )),
                    ),
                  ),

                if (isAdmin || isCashier)
                  const SizedBox(height: 16),

                Card(
                  elevation: 2,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.email_outlined),
                        title: const Text('Email'),
                        subtitle: Text(userData.email ?? 'Não definido'),
                        trailing: isEmailVerified
                            ? Tooltip(
                                message: 'Email verificado',
                                child: Icon(Icons.verified, color: Colors.green.shade600),
                              )
                            : Tooltip(
                                message: 'Email não verificado',
                                child: Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600),
                              ),
                      ),
                      const Divider(height: 1, indent: 72),
                      ListTile(
                        leading: const Icon(Icons.phone_outlined),
                        title: const Text('Telefone'),
                        subtitle: Text(userData.phoneNumber ?? 'Não definido'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Card(
                  elevation: 2,
                  child: Column(
                    children: [
                      _buildProfileListTile(
                        context: context,
                        icon: Icons.pin_outlined,
                        title: 'Alterar PIN de Transação',
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const ChangePinScreen(),
                        )),
                      ),
                      const Divider(height: 1, indent: 72),
                      _buildProfileListTile(
                        context: context,
                        icon: Icons.notifications_outlined,
                        title: 'Definições de Notificação',
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const NotificationSettingsScreen(),
                        )),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Card(
                  elevation: 2,
                  child: Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
                      final iconData = isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined;

                      return SwitchListTile(
                        secondary: Icon(iconData),
                        title: const Text('Modo Escuro'),
                        value: isDarkMode,
                        onChanged: (bool value) {
                          final newMode = value ? ThemeMode.dark : ThemeMode.light;
                          themeProvider.setTheme(newMode);
                        },
                        activeTrackColor: Theme.of(context).colorScheme.primary,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                Card(
                  elevation: 2,
                  child: Column(
                    children: [
                      _buildProfileListTile(
                        context: context,
                        icon: Icons.gavel_rounded,
                        title: 'Termos e Condições',
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const TermsAndConditionsScreen(),
                        )),
                      ),
                      const Divider(height: 1, indent: 72),
                      _buildProfileListTile(
                        context: context,
                        icon: Icons.shield_outlined,
                        title: 'Política de Privacidade',
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyScreen(),
                        )),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Card(
                  elevation: 2,
                  child: ListTile(
                    leading: Icon(Icons.logout, color: theme.colorScheme.error),
                    title: Text('Terminar Sessão', style: TextStyle(color: theme.colorScheme.error)),
                    onTap: _showLogoutConfirmation,
                  ), 
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildKycStatusCard(BuildContext context, String kycStatus) {
    final theme = Theme.of(context);
    IconData icon;
    Color iconColor;
    String title;
    String subtitle;
    VoidCallback? onTap;

    switch (kycStatus) {
      case 'verified':
      case 'approved':
        icon = Icons.verified_user_outlined;
        iconColor = Colors.green.shade600;
        title = 'Conta Verificada';
        subtitle = 'A sua identidade foi confirmada com sucesso.';
        onTap = null;
        break;
      case 'pending':
        icon = Icons.hourglass_top_outlined;
        iconColor = Colors.orange.shade600;
        title = 'Verificação em Análise';
        subtitle = 'Os seus documentos estão a ser revistos.';
        onTap = null;
        break;
      case 'rejected':
        icon = Icons.error_outline;
        iconColor = theme.colorScheme.error;
        title = 'Verificação Rejeitada';
        subtitle = 'Toque aqui para submeter novamente.';
        onTap = () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const KycVerificationScreen()),
        );
        break;
      default: // unverified
        icon = Icons.gpp_maybe_outlined;
        iconColor = Colors.orange.shade600;
        title = 'Verificar Identidade';
        subtitle = 'Proteja a sua conta e desbloqueie todas as funcionalidades.';
        onTap = () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const KycVerificationScreen()),
        );
    }

    return Card(
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, color: iconColor, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: onTap != null ? const Icon(Icons.keyboard_arrow_right) : null,
        onTap: onTap,
      ),
    );
  }
  
  ListTile _buildProfileListTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    bool isSpecial = false,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: isSpecial ? theme.colorScheme.primary : null),
      title: Text(
        title, 
        style: isSpecial 
          ? TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary) 
          : null,
      ),
      trailing: onTap != null ? const Icon(Icons.keyboard_arrow_right) : null,
      onTap: onTap,
    );
  }
}