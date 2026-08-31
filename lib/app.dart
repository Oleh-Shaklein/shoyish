import 'package:flutter/material.dart';
import 'features/map/splash_screen.dart'; // Імпортуємо заставку

class MapMenuApp extends StatelessWidget {
  const MapMenuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MapMenu AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      // Першим екраном стає заставка з 3-секундним делеєм
      home: const SplashScreen(),
    );
  }
}