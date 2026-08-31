import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  // Ініціалізація додатку з підтримкою Riverpod для керування станом
  runApp(
    const ProviderScope(
      child: MapMenuApp(),
    ),
  );
}