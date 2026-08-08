import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../utils/constants.dart';

/// Reproduces the training-time eval preprocessing:
/// decode → RGB → resize to 224×224 → normalize → HWC→CHW → Float32.
class ImagePreprocessor {
  const ImagePreprocessor();

  /// Preprocess an image file into a [1, 3, 224, 224] Float32 tensor in
  /// NCHW layout, matching the ONNX model input.
  Float32List preprocessFile(File file) {
    final bytes = file.readAsBytesSync();
    return preprocessBytes(bytes);
  }

  /// Preprocess raw image bytes into a CHW float32 tensor.
  Float32List preprocessBytes(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const FormatException('Unable to decode image.');
    }

    // Ensure an RGB (3 channel) image.
    final rgb = decoded.numChannels == 3
        ? decoded
        : decoded.convert(numChannels: 3);

    // Resize (stretch) to 224×224 using bilinear interpolation, matching the
    // torchvision T.Resize((224, 224)) eval transform.
    final resized = img.copyResize(
      rgb,
      width: modelInputSize,
      height: modelInputSize,
      interpolation: img.Interpolation.linear,
    );

    final tensor = Float32List(1 * modelInputChannels * modelInputSize * modelInputSize);

    final size = modelInputSize;
    var idx = 0;
    for (var c = 0; c < modelInputChannels; c++) {
      final mean = imageNetMean[c];
      final std = imageNetStd[c];
      for (var y = 0; y < size; y++) {
        for (var x = 0; x < size; x++) {
          final pixel = resized.getPixel(x, y);
          final value = switch (c) {
            0 => pixel.r.toDouble(),
            1 => pixel.g.toDouble(),
            _ => pixel.b.toDouble(),
          };
          tensor[idx++] = (value / 255.0 - mean) / std;
        }
      }
    }
    return tensor;
  }

  /// Verifies the tensor length and returns the expected input shape.
  List<int> shapeOf(Float32List tensor) {
    final expected = modelInputChannels * modelInputSize * modelInputSize;
    if (tensor.length != expected) {
      throw ArgumentError(
        'Unexpected tensor length ${tensor.length}, expected $expected',
      );
    }
    return [1, modelInputChannels, modelInputSize, modelInputSize];
  }
}
