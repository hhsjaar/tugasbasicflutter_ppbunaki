import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:media_kit/media_kit.dart';
import 'package:mobile_ta/providers/auth_provider.dart';
import 'package:mobile_ta/widget/petugas_main_widget.dart';
import 'package:mobile_ta/widget/warga_main_widget.dart';
import 'package:provider/provider.dart';
import 'pages/auth/login_page.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id_ID', null);
  MediaKit.ensureInitialized();
  await dotenv.load(fileName: ".env");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
          lazy: false, // Important to instantiate immediately
        ),
      ],
      child: MaterialApp(
        title: 'Bank Sampah',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late Future<void> _authFuture;

  @override
  void initState() {
    super.initState();
    _authFuture = _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    // Add slight delay to ensure widget tree is built
    await Future.delayed(Duration.zero);
    await Provider.of<AuthProvider>(context, listen: false).checkAuth();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _authFuture,
      builder: (context, snapshot) {
        // Show loading screen while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Get auth state after initialization
        final authProvider = Provider.of<AuthProvider>(context);

        if (authProvider.isAuthenticated) {
          final user = authProvider.userData;
          if (user?['role'] == 'warga') {
            return const WargaMainWrapper();
          } else if (user?['role'] == 'petugas') {
            return const PetugasMainWrapper();
          }
        }

        // Show login page if not authenticated
        return const LoginPage();
      },
    );
  }
}
