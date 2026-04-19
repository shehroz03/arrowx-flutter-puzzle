import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'game_board.dart';

void main() {
  runApp(
    const ProviderScope(
      child: ArrowGameApp(),
    ),
  );
}

class ArrowGameApp extends StatelessWidget {
  const ArrowGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arrow Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      home: const GameBoardScreen(),
    );
  }
}
