import 'package:flutter/material.dart';

/// Main app widget (UI will be added in next phase)
class LogPulseApp extends StatelessWidget {
  const LogPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LogPulse Analytics',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.analytics, size: 64, color: Colors.blue),
              SizedBox(height: 16),
              Text(
                'LogPulse Analytics',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Phase 1: Foundation Complete'),
              SizedBox(height: 4),
              Text('UI components coming in next phase'),
            ],
          ),
        ),
      ),
    );
  }
}
