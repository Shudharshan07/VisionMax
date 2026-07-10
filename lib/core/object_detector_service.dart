import 'dart:io';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

class ObjectDetectorService {
  late final ObjectDetector _detector;
  
  static const double smallAreaThreshold = 0.01; // 1%

  ObjectDetectorService() {
    _detector = ObjectDetector(
      options: ObjectDetectorOptions(
        mode: DetectionMode.single,
        classifyObjects: true,
        multipleObjects: true,
      ),
    );
  }

  /// Process a camera frame and return the detected objects.
  Future<List<DetectedObject>> processCameraImage(CameraImage image) async {
    final inputImage = _convertCameraImage(image);
    return await _detector.processImage(inputImage);
  }

  /// Converts a [CameraImage] from the camera plugin to an ML Kit [InputImage].
  InputImage _convertCameraImage(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final Uint8List yBuffer = image.planes[0].bytes; // Y plane
    final Uint8List uBuffer = image.planes[1].bytes; // U plane
    final Uint8List vBuffer = image.planes[2].bytes; // V plane

    final int ySize = width * height;
    final int uvSize = ySize ~/ 4; // U and V are quarter size
    final Uint8List bytes = Uint8List(ySize + 2 * uvSize);

    // Copy Y plane
    bytes.setRange(0, ySize, yBuffer);

    // Interleave V and U (NV21 order: Y, then VU)
    for (int i = 0; i < uvSize; i++) {
      bytes[ySize + 2 * i] = vBuffer[i];
      bytes[ySize + 2 * i + 1] = uBuffer[i];
    }

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(width.toDouble(), height.toDouble()),
        rotation: Platform.isAndroid ? InputImageRotation.rotation90deg : InputImageRotation.rotation0deg,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  /// Analyzes the detected objects and returns the navigation instruction.
  String analyzeDetections(List<DetectedObject> detections, int screenWidth, int screenHeight) {
    double leftArea = 0, rightArea = 0;
    final screenArea = screenWidth * screenHeight;
    final midpoint = screenWidth / 2;

    for (var detection in detections) {
      final rect = detection.boundingBox;
      final area = rect.width * rect.height;
      if (area / screenArea < smallAreaThreshold) {
        continue;
      }

      final xCenter = rect.left + (rect.width / 2);
      if (xCenter < midpoint) {
        leftArea += area;
      } else {
        rightArea += area;
      }
    }

    final leftPercentage = (leftArea / (screenArea / 2)) * 100;
    final rightPercentage = (rightArea / (screenArea / 2)) * 100;

    if (leftPercentage < 15 && rightPercentage > 40) {
      return 'Go left, right side blocked';
    } else if (rightPercentage < 15 && leftPercentage > 40) {
      return 'Go right, left side blocked';
    } else if (leftPercentage > 40 && rightPercentage > 40) {
      return 'Stop, path blocked';
    } else {
      return 'Clear path ahead';
    }
  }

  /// Closes the detector and releases resources.
  void dispose() {
    _detector.close();
  }
}
