import 'package:flutter/material.dart';

void main() {
  runApp(const MoijaApp());
}

class MoijaApp extends StatelessWidget {
  const MoijaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: SizedBox.shrink()),
    );
  }
}
