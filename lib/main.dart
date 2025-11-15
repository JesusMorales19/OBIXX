import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import './views/screens/login/login_view.dart';
import './views/screens/register/roles_view.dart';
import './views/screens/contratista/home_view.dart';
import './views/screens/trabajador/home_view.dart';
import './views/screens/contratista/profile_view.dart';
import './views/screens/trabajador/profile_view.dart';
import 'services/storage_service.dart';
import './core/utils/theme.dart';
import 'services/navigation_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  final hasSession = await StorageService.hasSession();
  runApp(MyApp(hasSession: hasSession));
}

class MyApp extends StatefulWidget {
  final bool hasSession;
  const MyApp({super.key, required this.hasSession});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OBIX',
      theme: AppTheme.lightTheme,
      navigatorKey: NavigationService.navigatorKey,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      locale: const Locale('es', 'ES'),
      initialRoute: widget.hasSession ? '/session-check' : '/login',
      routes: {
        '/login': (context) => const LoginView(),
        '/register': (context) => const RolesView(),
        '/home_contratista': (context) => const HomeViewContractor(),
        '/home_trabajador': (context) => const HomeViewEmployee(),
        '/profile_contratista': (context) => const ProfileView(),
        '/profile_trabajador': (context) => const ProfileViewEmployees(),
        '/session-check': (context) => const _SessionRedirector(),
      },
    );
  }
}

class _SessionRedirector extends StatefulWidget {
  const _SessionRedirector();

  @override
  State<_SessionRedirector> createState() => _SessionRedirectorState();
}

class _SessionRedirectorState extends State<_SessionRedirector> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    final user = await StorageService.getUser();
    final tipoUsuario = user?['tipoUsuario'];
    final email = user?['email'] as String?;

    if (email != null && tipoUsuario != null) {
      await NotificationService.instance.configureForUser(
        email: email,
        tipoUsuario: tipoUsuario,
      );
    }

    if (!mounted) return;

    if (tipoUsuario == 'contratista') {
      Navigator.of(context).pushReplacementNamed('/home_contratista');
    } else if (tipoUsuario == 'trabajador') {
      Navigator.of(context).pushReplacementNamed('/home_trabajador');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
