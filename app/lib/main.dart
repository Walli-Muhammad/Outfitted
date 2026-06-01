import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'providers/wardrobe_provider.dart';
import 'providers/outfit_provider.dart';
import 'providers/tryon_provider.dart';
import 'screens/wardrobe_screen.dart';
import 'screens/outfits_screen.dart';
import 'screens/tryon_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Safe try-catch wrapper for Firebase initialization.
  // Prevents startup crashes before Firebase configs are officially generated.
  try {
    await Firebase.initializeApp();
    print('Firebase initialized successfully.');
  } catch (e) {
    print('Firebase initialization deferred: $e');
    print('Please configure Firebase using FlutterFire CLI to activate live authentication.');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WardrobeProvider()),
        ChangeNotifierProvider(create: (_) => OutfitProvider()),
        ChangeNotifierProvider(create: (_) => TryOnProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Outfit Planner',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const MainDashboard(),
    );
  }
}

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    WardrobeScreen(),
    OutfitsScreen(),
    TryOnScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      // Modern flat Material 3 NavigationBar
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.checkroom_outlined),
            selectedIcon: Icon(Icons.checkroom),
            label: 'Wardrobe',
          ),
          NavigationDestination(
            icon: Icon(Icons.style_outlined),
            selectedIcon: Icon(Icons.style),
            label: 'Outfits',
          ),
          NavigationDestination(
            icon: Icon(Icons.face_retouching_natural_outlined),
            selectedIcon: Icon(Icons.face_retouching_natural),
            label: 'Try-On',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
