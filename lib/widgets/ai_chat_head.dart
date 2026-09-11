import 'package:flutter/material.dart';

import '../screens/ai_chat_screen.dart';
import '../services/ai_chat_context.dart';

class AiChatHead extends StatefulWidget {
  const AiChatHead({super.key});

  @override
  State<AiChatHead> createState() => _AiChatHeadState();
}

class _AiChatHeadState extends State<AiChatHead> {
  double _right = 14;
  double _bottom = 95;

  void _openChat() {
    final navigator = AiChatContext.navigatorKey.currentState;

    if (navigator == null) {
      return;
    }

    navigator.push(
      MaterialPageRoute(
        builder: (_) => ValueListenableBuilder<String?>(
          valueListenable: AiChatContext.disease,
          builder: (context, disease, _) {
            return ValueListenableBuilder<double?>(
              valueListenable: AiChatContext.confidence,
              builder: (context, confidence, _) {
                return AiChatScreen(
                  detectedDisease: disease,
                  confidence: confidence,
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _moveHead(DragUpdateDetails details) {
    final screenSize = MediaQuery.of(context).size;

    setState(() {
      _right -= details.delta.dx;
      _bottom -= details.delta.dy;

      const double headSize = 58;
      const double margin = 8;

      final maxRight = screenSize.width - headSize - margin;
      final maxBottom = screenSize.height - headSize - margin;

      _right = _right.clamp(margin, maxRight);

      _bottom = _bottom.clamp(margin, maxBottom);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: _right,
      bottom: _bottom,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _openChat,
        onPanUpdate: _moveHead,
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: const Color(0xFF0B6B3A),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF4CAF50), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.eco, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
