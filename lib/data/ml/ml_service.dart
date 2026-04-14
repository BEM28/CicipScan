import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:cicipscan/data/ml/inference_result.dart';

class MLService {
  static const String _modelPath = 'assets/models/1.tflite';
  static const String _labelsPath = 'assets/models/labels.txt';

  List<String> _labels = [];
  Interpreter? _interpreter;
  bool _isInitialized = false;

  int _inputHeight = 224;
  int _inputWidth = 224;
  int _inputChannels = 3;
  int _numClasses = 6;

  bool _isInputUint8 = false;
  bool _isOutputUint8 = false;

  List<int> _outputShape = [];
  double _outputScale = 1.0;
  int _outputZeroPoint = 0;

  final Map<int, String> _assetMapping = {
    142: 'Classic Lasagna',
    230: 'Satay Ayam',
    278: 'Nasi Lemak',
    1136: 'Beef Bourguignon',
    1144: 'Sushi Platter',
  };

  bool get isInitialized => _isInitialized;
  int get inputSize => _inputHeight;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final labelData = await rootBundle.loadString(_labelsPath);
      _labels = labelData
          .split('\n')
          .map((e) => e.trim())
          .where((label) => label.isNotEmpty && label != 'name')
          .toList();

      final options = InterpreterOptions()..threads = 4;
      _interpreter = await Interpreter.fromAsset(_modelPath, options: options);
      _interpreter!.allocateTensors();

      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);
      final inputShape = inputTensor.shape;
      final outputShape = outputTensor.shape;

      debugPrint('TFLite input  shape: $inputShape');
      debugPrint('TFLite input  type : ${inputTensor.type}');
      debugPrint('TFLite output shape: $outputShape');
      debugPrint('TFLite output type : ${outputTensor.type}');
      debugPrint('Labels loaded: $_labels');

      if (inputShape.length == 4) {
        _inputHeight = inputShape[1];
        _inputWidth = inputShape[2];
        _inputChannels = inputShape[3];
      }

      _numClasses = outputShape.last;

      _isInputUint8 = inputTensor.type == TensorType.uint8;
      _isOutputUint8 = outputTensor.type == TensorType.uint8;
      _outputShape = outputShape;

      if (_isOutputUint8) {
        final params = outputTensor.params;
        _outputScale = params.scale;
        _outputZeroPoint = params.zeroPoint;
        debugPrint(
          'Output quantization: '
          'scale=$_outputScale, '
          'zeroPoint=$_outputZeroPoint',
        );
      }

      _isInitialized = true;
      debugPrint(
        'MLService initialized: '
        'input=${_inputWidth}x$_inputHeight '
        '(${_isInputUint8 ? "uint8" : "float32"}), '
        'classes=$_numClasses, '
        'labels=${_labels.length}',
      );
      if (_numClasses != _labels.length) {
        debugPrint(
          'WARNING: Model has $_numClasses classes but '
          '${_labels.length} labels found!',
        );
      }
    } catch (e, st) {
      _isInitialized = false;
      debugPrint('MLService init failed: $e');
      debugPrint('$st');
      throw Exception('Failed to initialize MLService: $e');
    }
  }

  Future<InferenceResult> runInference(File imageFile) async {
    _ensureInitialized();

    final bytes = imageFile.readAsBytesSync();
    final img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Failed to decode image from file.');
    }

    return _classifyImage(decoded);
  }

  InferenceResult runInferenceOnImage(img.Image image) {
    _ensureInitialized();
    return _classifyImage(image);
  }

  InferenceResult _classifyImage(img.Image image) {
    final img.Image resized = img.copyResize(
      image,
      width: _inputWidth,
      height: _inputHeight,
    );

    final Object input;
    if (_isInputUint8) {
      final inputList = List.generate(
        1,
        (_) => List.generate(
          _inputHeight,
          (_) => List.generate(
            _inputWidth,
            (_) => List<int>.filled(_inputChannels, 0),
          ),
        ),
      );
      for (var y = 0; y < _inputHeight; y++) {
        for (var x = 0; x < _inputWidth; x++) {
          final pixel = resized.getPixel(x, y);
          inputList[0][y][x][0] = pixel.r.toInt();
          if (_inputChannels > 1) {
            inputList[0][y][x][1] = pixel.g.toInt();
          }
          if (_inputChannels > 2) {
            inputList[0][y][x][2] = pixel.b.toInt();
          }
        }
      }
      input = inputList;
    } else {
      final inputList = List.generate(
        1,
        (_) => List.generate(
          _inputHeight,
          (_) => List.generate(
            _inputWidth,
            (_) => List<double>.filled(_inputChannels, 0.0),
          ),
        ),
      );
      for (var y = 0; y < _inputHeight; y++) {
        for (var x = 0; x < _inputWidth; x++) {
          final pixel = resized.getPixel(x, y);
          inputList[0][y][x][0] = (pixel.r / 127.5) - 1.0;
          if (_inputChannels > 1) {
            inputList[0][y][x][1] = (pixel.g / 127.5) - 1.0;
          }
          if (_inputChannels > 2) {
            inputList[0][y][x][2] = (pixel.b / 127.5) - 1.0;
          }
        }
      }
      input = inputList;
    }

    final Object outputBuffer;
    if (_isOutputUint8) {
      if (_outputShape.length == 2 && _outputShape[0] == 1) {
        outputBuffer = List.generate(
          1,
          (_) => List<int>.filled(_numClasses, 0),
        );
      } else {
        outputBuffer = List<int>.filled(_numClasses, 0).reshape(_outputShape);
      }
    } else {
      if (_outputShape.length == 2 && _outputShape[0] == 1) {
        outputBuffer = List.generate(
          1,
          (_) => List<double>.filled(_numClasses, 0.0),
        );
      } else {
        outputBuffer = List<double>.filled(
          _numClasses,
          0.0,
        ).reshape(_outputShape);
      }
    }

    _interpreter!.run(input, outputBuffer);

    final List<num> rawList = [];
    if (outputBuffer is List<num>) {
      rawList.addAll(outputBuffer);
    } else if (outputBuffer is List &&
        outputBuffer.isNotEmpty &&
        outputBuffer[0] is List) {
      rawList.addAll((outputBuffer[0] as List).cast<num>());
    } else if (outputBuffer is List) {
      void flatten(dynamic item) {
        if (item is List) {
          for (var i in item) {
            flatten(i);
          }
        } else if (item is num) {
          rawList.add(item);
        }
      }

      flatten(outputBuffer);
    }

    final Float32List scores = Float32List(_numClasses);
    for (int i = 0; i < _numClasses && i < rawList.length; i++) {
      if (_isOutputUint8) {
        scores[i] = _outputScale * (rawList[i].toInt() - _outputZeroPoint);
      } else {
        scores[i] = rawList[i].toDouble();
      }
    }

    if (kDebugMode) {
      debugPrint('ML Inference Scores (first 10): ${scores.take(10).toList()}');
      if (scores.length > 10) {
        debugPrint('... total ${scores.length} scores');
      }
    }

    return _parseOutput(scores);
  }

  InferenceResult _parseOutput(Float32List scores) {
    int topIndex = -1;
    double maxConfidence = -1.0;

    for (int i = 0; i < scores.length; i++) {
      if (scores[i] > maxConfidence) {
        maxConfidence = scores[i];
        topIndex = i;
      }
    }

    if (maxConfidence < 0.2 || topIndex == -1) {
      return InferenceResult('No identity detected', 0.0);
    }

    if (_assetMapping.containsKey(topIndex)) {
      final label = _assetMapping[topIndex]!;
      debugPrint(
        'Asset match found: $label ($maxConfidence) at index $topIndex',
      );
      return InferenceResult(label, maxConfidence);
    }

    if (topIndex >= 0 && topIndex < _labels.length) {
      final label = _labels[topIndex];
      debugPrint(
        'Direct label match: $label ($maxConfidence) at index $topIndex',
      );
      return InferenceResult(label, maxConfidence);
    }

    debugPrint(
      'Inference: Index $topIndex ($maxConfidence) is not in asset list.',
    );

    return InferenceResult('Unlisted Food', maxConfidence);
  }

  void _ensureInitialized() {
    if (!_isInitialized || _interpreter == null) {
      throw Exception(
        'MLService is not initialized. '
        'Call init() first.',
      );
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _labels.clear();
    _isInitialized = false;
  }
}
