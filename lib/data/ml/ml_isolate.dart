import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'image_preprocessor.dart';

class IsolateRequest {
  final SendPort sendPort;
  final File imageFile;
  final String modelPath;
  final RootIsolateToken rootIsolateToken;

  IsolateRequest({
    required this.sendPort,
    required this.imageFile,
    required this.modelPath,
    required this.rootIsolateToken,
  });
}

class IsolateResponse {
  final Float32List? outputData;
  final String? error;

  IsolateResponse({this.outputData, this.error});
}

class MLIsolate {
  static Future<IsolateResponse> runInference(
    File imageFile,
    String modelAbsPath,
    RootIsolateToken rootToken,
  ) async {
    final receivePort = ReceivePort();

    await Isolate.spawn(
      _isolateEntry,
      IsolateRequest(
        sendPort: receivePort.sendPort,
        imageFile: imageFile,
        modelPath: modelAbsPath,
        rootIsolateToken: rootToken,
      ),
    );

    return await receivePort.first as IsolateResponse;
  }

  static Future<void> _isolateEntry(IsolateRequest request) async {
    try {
      BackgroundIsolateBinaryMessenger.ensureInitialized(
        request.rootIsolateToken,
      );

      final Float32List inputTensor = ImagePreprocessor.preprocessImage(
        request.imageFile,
      );

      final options = InterpreterOptions()..threads = 4;

      final interpreter = await Interpreter.fromAsset(
        request.modelPath,
        options: options,
      );
      final outputShape = interpreter.getOutputTensor(0).shape;
      final outputSize = outputShape.reduce((a, b) => a * b);

      var outputBuffer = Float32List(outputSize);

      var inputs = [
        inputTensor.buffer.asFloat32List().reshape([
          1,
          ImagePreprocessor.inputSize,
          ImagePreprocessor.inputSize,
          3,
        ]),
      ];

      var outputs = {
        0: [outputBuffer],
      };

      interpreter.runForMultipleInputs(inputs, outputs);

      interpreter.close();

      request.sendPort.send(IsolateResponse(outputData: outputBuffer));
    } catch (e) {
      request.sendPort.send(IsolateResponse(error: e.toString()));
    }
  }
}
