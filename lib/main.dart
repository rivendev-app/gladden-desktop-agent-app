import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'infrastructure/storage/objectbox_store.dart';
import 'infrastructure/storage/secure_storage_service.dart';
import 'presentation/blocs/chat_bloc.dart';
import 'presentation/blocs/settings_bloc.dart';
import 'presentation/blocs/usage_bloc.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/chat/chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final store = await ObjectBoxStore.create();
  final secureStorage = SecureStorageService();

  runApp(GladdenApp(store: store, secureStorage: secureStorage));
}

class GladdenApp extends StatelessWidget {
  final ObjectBoxStore store;
  final SecureStorageService secureStorage;

  const GladdenApp({
    super.key,
    required this.store,
    required this.secureStorage,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => SettingsBloc(secureStorage, store)..add(LoadSettings())),
        BlocProvider(create: (_) => ChatBloc(store, secureStorage)..add(LoadSessions())),
        BlocProvider(create: (_) => UsageBloc(store)..add(LoadUsage())),
      ],
      child: MaterialApp(
        title: 'Gladden',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo,
            brightness: Brightness.dark,
          ),
          textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
