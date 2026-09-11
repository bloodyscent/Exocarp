import 'package:flutter/material.dart';

import '../services/disease_info_service.dart';

class ScanDetailsScreen extends StatelessWidget {
  final String disease;
  final double confidence;
  final DateTime? dateTime;

  const ScanDetailsScreen({
    super.key,
    required this.disease,
    required this.confidence,
    this.dateTime,
  });

  @override
  Widget build(BuildContext context) {
    final diseaseInfo = DiseaseInfoService.getInfo(disease);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Scan Details',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 35, 24, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Disease header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A2116),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF164D32)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.eco, color: Color(0xFF4CAF50), size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'Disease Detected',
                        style: TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        disease,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B6B3A),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (dateTime != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _formatDateTime(dateTime!),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                if (diseaseInfo != null) ...[
                  _buildInfoCard(
                    icon: Icons.info_outline,
                    title: 'What is ${diseaseInfo.name}?',
                    content: diseaseInfo.description,
                  ),

                  const SizedBox(height: 14),

                  _buildInfoCard(
                    icon: Icons.biotech_outlined,
                    title: 'What causes it?',
                    content: diseaseInfo.causes,
                  ),

                  const SizedBox(height: 14),

                  _buildInfoCard(
                    icon: Icons.search,
                    title: 'Why might this leaf have ${diseaseInfo.name}?',
                    content: diseaseInfo.whyItMightAppear,
                  ),

                  const SizedBox(height: 14),

                  _buildInfoCard(
                    icon: Icons.eco_outlined,
                    title: 'Contributing Conditions',
                    content: diseaseInfo.contributingConditions,
                  ),

                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A2116),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF164D32)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.amber,
                          size: 22,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'EXOCARP provides an AI-based visual '
                            'prediction. A photograph alone cannot '
                            'confirm the exact cause of a disease. '
                            'For uncertain or serious cases, consult '
                            'a qualified agricultural professional.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A2116),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF164D32)),
                    ),
                    child: const Text(
                      'No additional information is available '
                      'for this scan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A2116),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF164D32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: const Color(0xFF4CAF50), size: 23),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour > 12
        ? dateTime.hour - 12
        : dateTime.hour == 0
        ? 12
        : dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return '${dateTime.year}-$month-$day • $hour:$minute $period';
  }
}
