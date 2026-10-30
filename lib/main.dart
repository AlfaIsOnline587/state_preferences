import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/user_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // << ChangeNotifierProvider
    return ChangeNotifierProvider(
      create: (_) => UserProvider()..loadUser(),
      child: Consumer<UserProvider>(
        builder: (context, provider, child) {
          return MaterialApp(
            title: 'State & Preferences',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
              ),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            themeMode: provider.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            home: const HomeScreen(),
          );
        },
      ),
    );
    // >> ChangeNotifierProvider
  }
}
