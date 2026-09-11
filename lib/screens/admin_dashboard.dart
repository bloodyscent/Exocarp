import 'package:flutter/material.dart';

import '../utils/fade_route.dart';
import 'home_screen.dart';
import 'reports_screen.dart';
import 'scan_records_screen.dart';
import 'users_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 21,
            letterSpacing: 0.3,
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              20,
              45,
              20,
              30,
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Admin icon
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    size: 52,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'EXOCARP Administration',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Manage the EXOCARP system and monitor scan activity.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 32),

                // Use EXOCARP
                _adminButton(
                  context,
                  icon: Icons.phone_android,
                  title: 'Use EXOCARP',
                  subtitle: 'Open the normal user application',
                  onPressed: () {
                    Navigator.push(
                      context,
                      fadeRoute(
                        const HomeScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 14),

                // Users
                _adminButton(
                  context,
                  icon: Icons.people_outline,
                  title: 'Users',
                  subtitle: 'View registered EXOCARP users',
                  onPressed: () {
                    Navigator.push(
                      context,
                      fadeRoute(
                        const UsersScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 14),

                // Scan Records
                _adminButton(
                  context,
                  icon: Icons.history,
                  title: 'Scan Records',
                  subtitle: 'View all recorded disease scans',
                  onPressed: () {
                    Navigator.push(
                      context,
                      fadeRoute(
                        const ScanRecordsScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 14),

                // Reports
                _adminButton(
                  context,
                  icon: Icons.bar_chart_rounded,
                  title: 'Reports',
                  subtitle: 'View system statistics and analysis',
                  onPressed: () {
                    Navigator.push(
                      context,
                      fadeRoute(
                        const ReportsScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 30),

                const Text(
                  'EXOCARP Admin Panel',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white38,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _adminButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: const Color(0xFF0A2116),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B6B3A),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 27,
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.white38,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}