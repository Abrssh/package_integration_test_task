import 'package:flutter/material.dart';
import 'package:package_integration_test_task/Screen/package_integration_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: PackageIntegrationScreen(),
    );
  }
}
