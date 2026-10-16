
import 'dart:convert';
import 'dart:typed_data';

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

    print('Model input shape: ${_interpreter!.getInputTensor(0).shape}');
    print('Model input type: ${_interpreter!.getInputTensor(0).type}');
    print('Model output shape: ${_interpreter!.getOutputTensor(0).shape}');

    final classNamesJson = await rootBundle.loadString(
      'assets/ai/class_names.json',
    );

    _classNames = List<String>.from(jsonDecode(classNamesJson));

    if (_classNames.length != numClasses) {
      _interpreter!.close();
      _interpreter = null;

      throw Exception(
        'Expected $numClasses classes, but found ${_classNames.length}.',
      );
    }

    print('EXOCARP AI model loaded successfully.');
    print('Classes: $_classNames');
  }

  Future<Map<String, dynamic>> predict(Uint8List imageBytes) async {
    if (_interpreter == null) {
      await loadModel();
    }

    final decodedImage = img.decodeImage(imageBytes);

    if (decodedImage == null) {
      throw Exception('Unable to decode image.');
    }

    final orientedImage = img.bakeOrientation(decodedImage);

    final resizedImage = img.copyResize(
      orientedImage,
      width: imageSize,
      height: imageSize,
    );

    final input = [
      List.generate(
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
      ),
    ];

    final output = [
      List<double>.filled(numClasses, 0.0),
    ];

    _interpreter!.run(input, output);

    final scores = output[0];

    if (scores.length != _classNames.length) {
      throw Exception(
        'Model returned ${scores.length} scores for ${_classNames.length} classes.',
      );
    }

    int bestIndex = 0;

    for (int i = 1; i < scores.length; i++) {
      if (scores[i] > scores[bestIndex]) {
        bestIndex = i;
      }
    }

    final disease = _classNames[bestIndex];
    final confidence = scores[bestIndex];

    print('--- EXOCARP PREDICTION SCORES ---');

    for (int i = 0; i < scores.length; i++) {
      print(
        '${_classNames[i]}: '
        '${(scores[i] * 100).toStringAsFixed(2)}%',
      );
    }

    print('Predicted disease: $disease');
    print(
      'Prediction confidence: '
      '${(confidence * 100).toStringAsFixed(2)}%',
    );
    print('--------------------------------');

    return {
      'disease': disease,
      'confidence': confidence,
    };
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}