import 'package:afercon_pay/firebase_options.dart';
import 'package:afercon_pay/providers/notification_provider.dart';
import 'package:afercon_pay/screens/auth/auth_gate.dart';
import 'package:afercon_pay/screens/authentication/login_screen.dart';
import 'package:afercon_pay/services/auth_service.dart';
import 'package:afercon_pay/services/firestore_service.dart';
import 'package:afercon_pay/services/notification_service.dart';
import 'package:afercon_pay/services/referral_service.dart';
import 'package:afercon_pay/theme/app_theme.dart';
import 'package:afercon_pay/theme/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kUnreadNotificationFlag = 'has_unread_notifications';

// Handler para notificações em background/terminado
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Usaremos o NotificationService para mostrar a notificação
  final notificationService = NotificationService();
  notificationService.showNotification(message);
  
  // Opcional: manter a flag para lógica interna
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(kUnreadNotificationFlag, true);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('pt_AO', null);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  if (!kIsWeb && !kDebugMode) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  await ReferralService().init();

  runApp(const AferconPayApp());
}

class AferconPayApp extends StatefulWidget {
  const AferconPayApp({super.key});

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);

  @override
  State<AferconPayApp> createState() => _AferconPayAppState();
}

class _AferconPayAppState extends State<AferconPayApp> with WidgetsBindingObserver {
  final NotificationService _notificationService = NotificationService();
  final NotificationProvider _notificationProvider = NotificationProvider();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _notificationService.setNotificationProvider(_notificationProvider);
    _notificationService.initialize();

    // Listener para notificações com a app em primeiro plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _notificationService.showNotification(message);
      _notificationProvider.setUnreadStatus(true); // CORRIGIDO
    });
    
    _notificationService.clearAppBadge();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _notificationService.clearAppBadge();
      _notificationProvider.checkInitialStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<NotificationService>(create: (_) => _notificationService),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => _notificationProvider,
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ScreenUtilInit(
            designSize: const Size(390, 844),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (context, child) {
              return MaterialApp(
                title: 'Afercon Pay',
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeProvider.themeMode,
                navigatorObservers: kIsWeb
                    ? []
                    : <NavigatorObserver>[AferconPayApp.observer],
                initialRoute: '/',
                routes: {
                  '/': (context) => const AuthGate(),
                  '/login': (context) => const LoginScreen(),
                },
                debugShowCheckedModeBanner: false,
              );
            },
          );
        },
      ),
    );
  }
}
