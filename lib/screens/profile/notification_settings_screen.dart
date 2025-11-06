import 'package:afercon_pay/services/auth_service.dart';
import 'package:afercon_pay/services/notification_service.dart';
import 'package:afercon_pay/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  String? _userId;
  bool _isLoading = true;

  final Map<String, String> _topicDisplayNames = {
    'transactions': 'Notificações de Transações',
    'security': 'Alertas de Segurança',
    'promotions': 'Promoções e Novidades',
  };

  final Map<String, String> _topicDescriptions = {
    'transactions': 'Receber alertas sobre novas transações',
    'security': 'Receber alertas importantes de segurança',
    'promotions': 'Receber alertas sobre as nossas novidades',
  };

  Map<String, bool> _preferences = {};

  @override
  void initState() {
    super.initState();
    _loadCurrentUserAndPreferences();
  }

  Future<void> _loadCurrentUserAndPreferences() async {
    final currentUser = _authService.getCurrentUser();
    if (!mounted) return;

    if (currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    _userId = currentUser.uid;
    final userPreferences = await _notificationService.getUserPreferences(_userId!);
    if (!mounted) return;

    setState(() {
      _preferences = {
        for (var topic in _topicDisplayNames.keys)
          topic: userPreferences[topic] ?? (topic != 'promotions'),
      };
      _isLoading = false;
    });
  }

  Future<void> _onPreferenceChanged(String topic, bool isEnabled) async {
    if (_userId == null) return;

    setState(() {
      _preferences[topic] = isEnabled;
    });

    try {
      await _notificationService.updateSubscription(_userId!, topic, isEnabled);
    } catch (e) {
      if (mounted) {
        setState(() {
          _preferences[topic] = !isEnabled;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao atualizar a preferência de notificação.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: Text('Definições de Notificação')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userId == null
              ? const Center(child: Text('Utilizador não encontrado.'))
              : ListView(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
                  children: [
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      child: Column(
                        children: _topicDisplayNames.entries.map((entry) {
                          final topic = entry.key;
                          final title = entry.value;
                          final isLast = topic == _topicDisplayNames.keys.last;

                          return Column(
                            children: [
                              SwitchListTile(
                                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                                title: Text(title, style: TextStyle(fontSize: 15.sp)),
                                subtitle: Text(
                                  _topicDescriptions[topic]!,
                                  style: TextStyle(fontSize: 13.sp),
                                ),
                                value: _preferences[topic] ?? false,
                                onChanged: (bool value) {
                                  _onPreferenceChanged(topic, value);
                                },
                                activeThumbColor: Theme.of(context).primaryColor,
                              ),
                              if (!isLast) const Divider(height: 1, indent: 72),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
    );
  }
}
