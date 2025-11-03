import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wastewatch_admin/providers/theme_provider.dart';
import 'package:wastewatch_admin/screens/login_screen.dart';
import 'package:wastewatch_admin/screens/report_management_screen.dart';
import 'package:wastewatch_admin/screens/user_management_screen.dart';
import 'package:wastewatch_admin/screens/profile_screen.dart';
import 'package:wastewatch_admin/dashboard_content.dart';
import 'package:wastewatch_admin/services/clustering_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure logging
  Logger.root.level = Level.INFO; // Set the root level to INFO to reduce verbosity
  Logger.root.onRecord.listen((record) {
    // Only print logs in debug mode
    if (kDebugMode) {
      print('${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
      if (record.error != null) print('Error: ${record.error}');
    }
  });

  // Load env file
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const WasteWatchAdminApp(),
    ),
  );
}

class WasteWatchAdminApp extends StatelessWidget {
  const WasteWatchAdminApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'WasteWatch Admin',
          debugShowCheckedModeBanner: false, // Hides the debug banner
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.light),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.dark),
            useMaterial3: true,
          ),
          themeMode: themeProvider.themeMode,
          home: StreamBuilder<AuthState>(
            stream: Supabase.instance.client.auth.onAuthStateChange,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              if (snapshot.data!.session != null) {
                return const AdminHomePage();
              }
              return const LoginScreen();
            },
          ),
        );
      },
    );
  }
}

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  
  // Handles navigation logic, including the special case for 'Log Out'.
  void _onNavigate(int index) async {
    if (index == 5) { // Index 5 is designated for 'Log Out' in the sidebar
      await _confirmSignOut(context);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final double dialogWidth = (screenWidth * 0.25).clamp(400.0, 600.0);

    final didRequestSignOut = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: dialogWidth),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Confirm Log Out', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  const Text('Are you sure you want to log out?', style: TextStyle(fontSize: 16), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(child: OutlinedButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel'))),
                      const SizedBox(width: 16),
                      Expanded(child: ElevatedButton(onPressed: () => Navigator.of(context).pop(true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text('Log Out'))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (didRequestSignOut == true) {
      await Supabase.instance.client.auth.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    // The list of main content widgets.
    final List<Widget> pages = [
      DashboardContent(currentIndex: _selectedIndex, onNavigate: _onNavigate),
      const UserManagementScreen(),
      const ReportManagementScreen(),
      const ClusterMapScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: Row(
        children: [
          // The sidebar is now persistent across all pages.
          DashboardContent.buildSidebar(context, _selectedIndex, _onNavigate),
          // The content area switches between pages using an IndexedStack.
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: pages,
            ),
          ),
        ],
      ),
    );
  }
}
