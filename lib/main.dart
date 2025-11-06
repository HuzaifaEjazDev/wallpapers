import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wallpapers/viewmodels/mockup_provider.dart';
import 'package:wallpapers/viewmodels/product_provider.dart';
import 'dart:async'; // For unawaited
import 'views/home_screen.dart';
import 'views/category_screen.dart';
import 'views/settings_screen.dart';
import 'views/mockup/mockup_category_screen.dart'; // Add this import
import 'services/pixabay_service.dart';

void main() {
  // Preload category data when the app starts
  WidgetsFlutterBinding.ensureInitialized();
  _preloadData();
  
  runApp(const MyApp());
}

// Preload data in the background
Future<void> _preloadData() async {
  // Don't wait for this to complete, let it run in the background
  unawaited(PixabayService.preloadCategories());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => MockupProvider()),
      ],
      child: MaterialApp(
        title: 'Wallpapers',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.dark,
          ),
        ),
        home: const MainScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const CategoryScreen(),
    const MockupCategoryScreen(),
    const SettingsScreen(),
     // Add MockupScreen as the last screen
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.grey.shade900,
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.grey[100],
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Category',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome), // Use a different icon for Mockup
            label: 'Mockup',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}