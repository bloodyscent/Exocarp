import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        title: const Text(
          'Reports',
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
            colors: [Color(0xFF0B6B3A), Color(0xFF063D24), Color(0xFF050805)],
          ),
        ),

        child: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('scans').snapshots(),

            builder: (context, scanSnapshot) {
              if (scanSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              if (scanSnapshot.hasError) {
                return _errorState(
                  'Unable to load reports.\n\n'
                  '${scanSnapshot.error}',
                );
              }

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .snapshots(),

                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  if (userSnapshot.hasError) {
                    return _errorState(
                      'Unable to load user statistics.\n\n'
                      '${userSnapshot.error}',
                    );
                  }

                  final scans = scanSnapshot.data?.docs ?? [];

                  final users = userSnapshot.data?.docs ?? [];

                  return _buildReport(scans, users);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildReport(
    List<QueryDocumentSnapshot> scans,
    List<QueryDocumentSnapshot> users,
  ) {
    int healthyCount = 0;
    int diseasedCount = 0;

    double totalConfidence = 0;

    final Map<String, int> diseaseCounts = {};

    for (final scan in scans) {
      final data = scan.data() as Map<String, dynamic>;

      final disease = data['disease']?.toString() ?? 'Unknown';

      final confidence = (data['confidence'] as num?)?.toDouble() ?? 0.0;

      totalConfidence += confidence;

      if (disease.toLowerCase() == 'healthy') {
        healthyCount++;
      } else {
        diseasedCount++;
      }

      diseaseCounts[disease] = (diseaseCounts[disease] ?? 0) + 1;
    }

    final totalScans = scans.length;
    final totalUsers = users.length;

    final averageConfidence = totalScans == 0
        ? 0.0
        : totalConfidence / totalScans;

    String mostDetectedDisease = 'None';
    int mostDetectedCount = 0;

    if (diseaseCounts.isNotEmpty) {
      final entries = diseaseCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      mostDetectedDisease = entries.first.key;
      mostDetectedCount = entries.first.value;
    }

    final healthyPercentage = totalScans == 0 ? 0.0 : healthyCount / totalScans;

    final diseasedPercentage = totalScans == 0
        ? 0.0
        : diseasedCount / totalScans;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 45, 16, 30),

      children: [
        const SizedBox(height: 20),

        const Text(
          'System Reports',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 7),

        const Text(
          'Overview of EXOCARP activity and detection results.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.white70),
        ),

        const SizedBox(height: 28),

        // Total Users Registered + Total Scans
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                icon: Icons.people_outline,
                title: 'Total Users Registered',
                value: totalUsers.toString(),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _summaryCard(
                icon: Icons.document_scanner_outlined,
                title: 'Total Scans',
                value: totalScans.toString(),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Healthy + Diseased
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                icon: Icons.eco_outlined,
                title: 'Healthy Leaves',
                value: healthyCount.toString(),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _summaryCard(
                icon: Icons.warning_amber_rounded,
                title: 'Diseased Leaves',
                value: diseasedCount.toString(),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Average confidence + disease types
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                icon: Icons.speed_outlined,
                title: 'Average Confidence',
                value: '${(averageConfidence * 100).toStringAsFixed(1)}%',
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _summaryCard(
                icon: Icons.category_outlined,
                title: 'Disease Types',
                value: diseaseCounts.keys
                    .where((disease) => disease.toLowerCase() != 'healthy')
                    .length
                    .toString(),
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),

        // Scan Overview
        _sectionTitle('Scan Overview', Icons.analytics_outlined),

        const SizedBox(height: 12),

        Card(
          color: const Color(0xFF0A2116),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),

          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _percentageRow(
                  title: 'Healthy',
                  count: healthyCount,
                  percentage: healthyPercentage,
                ),

                const SizedBox(height: 20),

                _percentageRow(
                  title: 'Diseased',
                  count: diseasedCount,
                  percentage: diseasedPercentage,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 28),

        // Most detected disease
        _sectionTitle('Most Detected Disease', Icons.trending_up),

        const SizedBox(height: 12),

        Card(
          color: const Color(0xFF0A2116),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),

          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B6B3A),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.local_florist,
                    color: Colors.white,
                    size: 28,
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Most frequently detected',
                        style: TextStyle(fontSize: 13, color: Colors.white54),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        mostDetectedDisease,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      if (mostDetectedCount > 0) ...[
                        const SizedBox(height: 3),

                        Text(
                          '$mostDetectedCount '
                          '${mostDetectedCount == 1 ? 'detection' : 'detections'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 28),

        // Disease Breakdown
        _sectionTitle('Disease Breakdown', Icons.bar_chart_rounded),

        const SizedBox(height: 12),

        if (diseaseCounts.isEmpty)
          _emptyBreakdown()
        else
          ..._buildDiseaseBreakdown(diseaseCounts, totalScans),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      color: const Color(0xFF0A2116),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: const Color(0xFF0B6B3A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 23),
            ),

            const SizedBox(height: 14),

            Text(
              value,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 3),

            Text(
              title,
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 21, color: Colors.white),

        const SizedBox(width: 8),

        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _percentageRow({
    required String title,
    required int count,
    required double percentage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            Text(
              '$count scans',
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),

            const SizedBox(width: 10),

            Text(
              '${(percentage * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),

        const SizedBox(height: 9),

        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 9,
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0B6B3A)),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildDiseaseBreakdown(
    Map<String, int> diseaseCounts,
    int totalScans,
  ) {
    final entries = diseaseCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries.map((entry) {
      final percentage = totalScans == 0 ? 0.0 : entry.value / totalScans;

      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        color: const Color(0xFF0A2116),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  Text(
                    '${entry.value}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 9),

              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 8,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF0B6B3A),
                  ),
                ),
              ),

              const SizedBox(height: 6),

              Text(
                '${(percentage * 100).toStringAsFixed(1)}% of all scans',
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _emptyBreakdown() {
    return Card(
      color: const Color(0xFF0A2116),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.bar_chart_outlined, size: 55, color: Colors.white38),

            SizedBox(height: 15),

            Text(
              'No scan data available yet.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),

            const SizedBox(height: 15),

            const Text(
              'Unable to load reports',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
