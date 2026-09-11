import 'package:flutter/material.dart';

class AiChatContext {
  AiChatContext._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static final ValueNotifier<String?> disease = ValueNotifier<String?>(null);

  static final ValueNotifier<double?> confidence = ValueNotifier<double?>(null);

  static void setScanResult({
    required String disease,
    required double confidence,
  }) {
    AiChatContext.disease.value = disease;
    AiChatContext.confidence.value = confidence;
  }

  static void clearScanResult() {
    disease.value = null;
    confidence.value = null;
  }
}
