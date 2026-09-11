import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/ai_chat_context.dart';
import '../services/ai_service.dart';
import '../services/disease_info_service.dart';
import '../services/firestore_service.dart';
import '../utils/fade_route.dart';
import 'scan_screen.dart';

class ResultScreen extends StatefulWidget {
  final File image;

  const ResultScreen({super.key, required this.image});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final AiService _aiService = AiService();
  final FirestoreService _firestoreService = FirestoreService();

  String? _disease;
  double? _confidence;
  String? _error;

  bool _isAnalyzing = true;
  bool _isSaving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _analyzeImage();
  }

  Future<void> _analyzeImage() async {
    try {
      final imageBytes = await widget.image.readAsBytes();

      final result = await _aiService.predict(imageBytes);

      if (!mounted) return;

      setState(() {
        _disease = result['disease'] as String;
        _confidence = result['confidence'] as double;
        _isAnalyzing = false;
      });

      AiChatContext.setScanResult(disease: _disease!, confidence: _confidence!);

      await _saveScanResult();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _saveScanResult() async {
    if (_disease == null || _confidence == null) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _error = 'No signed-in user found.';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isSaving = true;
      });
    }

    try {
      await _firestoreService.saveScanResult(
        userId: user.uid,
        disease: _disease!,
        confidence: _confidence!,
      );

      if (!mounted) return;

      setState(() {
        _saved = true;
        _isSaving = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _error = 'Unable to save scan history:\n$e';
      });
    }
  }

  @override
  void dispose() {
    _aiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diseaseInfo = _disease == null
        ? null
        : DiseaseInfoService.getInfo(_disease!);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Detection Result',
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 45, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 25),

                // Scanned image
                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    border: Border.all(color: Colors.white38, width: 1.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(widget.image, fit: BoxFit.contain),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Detection Result',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 30),

                if (_isAnalyzing) ...[
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Analyzing mango leaf...',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                ] else if (_error != null) ...[
                  const Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Unable to complete the scan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ] else ...[
                  const Text(
                    'Disease Detected',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    _disease ?? 'Unknown',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    'Confidence',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    '${((_confidence ?? 0) * 100).toStringAsFixed(1)}%',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 15),

                  if (_isSaving)
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Saving scan history...',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    )
                  else if (_saved)
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Scan saved to history',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),

                  const SizedBox(height: 30),

                  // Disease information
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
                              'EXOCARP provides an AI-based visual prediction. '
                              'A photograph alone cannot confirm the exact '
                              'cause of a disease. For uncertain or serious '
                              'cases, consult a qualified agricultural professional.',
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
                  ],
                ],

                const SizedBox(height: 30),

                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      fadeRoute(const ScanScreen()),
                    );
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Scan Another Leaf',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
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
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
        ],
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
}
