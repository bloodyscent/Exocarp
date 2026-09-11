import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class AiService {
  Interpreter? _interpreter;
  List<String> _classNames = [];

  static const int imageSize = 224;
  static const int numClasses = 8;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset(
      'assets/ai/exocarp_mango_disease_model.tflite',
    );

    final classNamesJson = await rootBundle.loadString(
      'assets/ai/class_names.json',
    );

    _classNames = List<String>.from(jsonDecode(classNamesJson));
  }

  Future<Map<String, dynamic>> predict(Uint8List imageBytes) async {
    if (_interpreter == null) {
      await loadModel();
    }

    final decodedImage = img.decodeImage(imageBytes);

    if (decodedImage == null) {
      throw Exception('Unable to decode image.');
    }

    final resizedImage = img.copyResize(
      decodedImage,
      width: imageSize,
      height: imageSize,
    );

    final input = List.generate(
      imageSize,
      (y) => List.generate(
        imageSize,
        (x) {
          final pixel = resizedImage.getPixel(x, y);

          return [
            pixel.r.toDouble(),
            pixel.g.toDouble(),
            pixel.b.toDouble(),
          ];
        },
      ),
    );

    final output = List.generate(
      1,
      (_) => List.filled(numClasses, 0.0),
    );

    _interpreter!.run(
      [input],
      output,
    );

    final probabilities = output[0];

    int bestIndex = 0;

    for (int i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > probabilities[bestIndex]) {
        bestIndex = i;
      }
    }

    return {
      'disease': _classNames[bestIndex],
      'confidence': probabilities[bestIndex],
    };
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}