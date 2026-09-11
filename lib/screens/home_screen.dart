import 'package:flutter/material.dart';

import 'scan_screen.dart';
import 'history_screen.dart';
import '../utils/fade_route.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        title: const Text(
          'EXOCARP',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 21,
            letterSpacing: 0.5,
          ),
        ),
      ),

      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B6B3A),
              Color(0xFF063D24),
              Color(0xFF050805),
            ],
          ),
        ),

        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 45, 24, 24),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 25),

                Center(
                  child: Image.asset(
                    'assets/Exocarp.png',
                    height: 120,
                  ),
                ),

                const SizedBox(height: 25),

                const Text(
                  'Mango Leaf Disease Detection',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 15),

                const Text(
                  'Scan a mango leaf to detect possible diseases.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 50),

                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      fadeRoute(const ScanScreen()),
                    );
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Scan Mango Leaf',
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      fadeRoute(const HistoryScreen()),
                    );
                  },
                  icon: const Icon(Icons.history),
                  label: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Scan History',
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}