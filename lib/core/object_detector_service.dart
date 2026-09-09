import 'dart:io';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

enum ScreenRegion { left, center, right }

enum ProximityLevel { safe, caution, critical }

enum FrameSafetyStatus { ok, coveredLens, nearbyWall }

class FrameSafetyResult {
  final FrameSafetyStatus status;
  final String? message;
  final double luminance;
  final double variance;

  const FrameSafetyResult({
    required this.status,
    this.message,
    required this.luminance,
    required this.variance,
  });
}

class DetectionAnalysis {
  final String instruction;
  final ProximityLevel proximity;
  final ScreenRegion region;
  final String? detectedLabel;
  final bool isCritical;

  const DetectionAnalysis({
    required this.instruction,
    required this.proximity,
    required this.region,
    this.detectedLabel,
    required this.isCritical,
  });
}

class ObjectDetectorService {
  late final ObjectDetector _detector;

  static const double coveredLensThreshold = 10.0;
  static const double nearbyWallThreshold = 15.0;

  static const double leftRegionThreshold = 0.35;
  static const double rightRegionThreshold = 0.65;

  static const double safeCoverageThreshold = 0.15;
  static const double criticalCoverageThreshold = 0.30;

  static const double minimumObjectCoverage = 0.01;

  ObjectDetectorService() {
    _detector = ObjectDetector(
      options: ObjectDetectorOptions(
        mode: DetectionMode.stream,
        classifyObjects: true,
        multipleObjects: true,
      ),
    );
  }

  Future<List<DetectedObject>> processCameraImage(CameraImage image) async {
    final inputImage = _convertCameraImage(image);
    return await _detector.processImage(inputImage);
  }

  FrameSafetyResult runFrameSafetyChecks(CameraImage image) {
    final luminance = _calculateAverageLuminance(image);
    final variance = _calculatePixelVariance(image);

    if (luminance < coveredLensThreshold) {
      return FrameSafetyResult(
        status: FrameSafetyStatus.coveredLens,
        message: 'Camera is covered or environment is too dark.',
        luminance: luminance,
        variance: variance,
      );
    }

    if (variance < nearbyWallThreshold) {
      return FrameSafetyResult(
        status: FrameSafetyStatus.nearbyWall,
        message: 'Obstacle or wall is extremely close.',
        luminance: luminance,
        variance: variance,
      );
    }

    return FrameSafetyResult(
      status: FrameSafetyStatus.ok,
      luminance: luminance,
      variance: variance,
    );
  }

  double _calculateAverageLuminance(CameraImage image) {
    final bytes = image.planes[0].bytes;
    final int byteCount = bytes.length;
    if (byteCount == 0) return 0.0;

    const int sampleStep = 64;
    int sum = 0;
    int count = 0;

    if (Platform.isIOS) {
      for (int i = 0; i + 3 < byteCount; i += sampleStep) {
        final b = bytes[i];
        final g = bytes[i + 1];
        final r = bytes[i + 2];
        final lum = (0.299 * r + 0.587 * g + 0.114 * b).round();
        sum += lum.clamp(0, 255);
        count++;
      }
    } else {
      for (int i = 0; i < byteCount; i += sampleStep) {
        sum += bytes[i];
        count++;
      }
    }

    return count > 0 ? sum / count : 0.0;
  }

  double _calculatePixelVariance(CameraImage image) {
    final bytes = image.planes[0].bytes;
    final int byteCount = bytes.length;
    if (byteCount == 0) return 0.0;

    const int sampleStep = 64;
    final List<int> samples = [];

    if (Platform.isIOS) {
      for (int i = 0; i + 3 < byteCount; i += sampleStep) {
        final b = bytes[i];
        final g = bytes[i + 1];
        final r = bytes[i + 2];
        final lum = (0.299 * r + 0.587 * g + 0.114 * b).round();
        samples.add(lum.clamp(0, 255));
      }
    } else {
      for (int i = 0; i < byteCount; i += sampleStep) {
        samples.add(bytes[i]);
      }
    }

    if (samples.isEmpty) return 0.0;

    final double mean =
        samples.reduce((a, b) => a + b) / samples.length;
    double sumSquaredDiff = 0.0;
    for (final value in samples) {
      final double diff = value - mean;
      sumSquaredDiff += diff * diff;
    }
    return sumSquaredDiff / samples.length;
  }

  ScreenRegion getScreenRegion(Rect rect, int screenWidth) {
    final double xCenter = rect.left + (rect.width / 2);
    final double normalizedCenter = xCenter / screenWidth;

    if (normalizedCenter < leftRegionThreshold) {
      return ScreenRegion.left;
    } else if (normalizedCenter > rightRegionThreshold) {
      return ScreenRegion.right;
    } else {
      return ScreenRegion.center;
    }
  }

  ProximityLevel getProximityLevel(Rect rect, int screenWidth, int screenHeight) {
    final double screenArea = screenWidth.toDouble() * screenHeight.toDouble();
    if (screenArea <= 0) return ProximityLevel.safe;
    final double coverageRatio = (rect.width * rect.height) / screenArea;

    if (coverageRatio > criticalCoverageThreshold) {
      return ProximityLevel.critical;
    } else if (coverageRatio >= safeCoverageThreshold) {
      return ProximityLevel.caution;
    } else {
      return ProximityLevel.safe;
    }
  }

  DetectionAnalysis analyzeDetections(
      List<DetectedObject> detections, int screenWidth, int screenHeight) {
    final double screenArea = screenWidth.toDouble() * screenHeight.toDouble();

    final List<DetectedObject> significantObjects = detections.where((obj) {
      final area = obj.boundingBox.width * obj.boundingBox.height;
      return (area / screenArea) >= minimumObjectCoverage;
    }).toList();

    if (significantObjects.isEmpty) {
      return const DetectionAnalysis(
        instruction: 'Clear path ahead',
        proximity: ProximityLevel.safe,
        region: ScreenRegion.center,
        isCritical: false,
      );
    }

    DetectedObject? highestPriorityObject;
    int highestPriorityScore = -1;

    for (final obj in significantObjects) {
      final region = getScreenRegion(obj.boundingBox, screenWidth);
      final proximity = getProximityLevel(obj.boundingBox, screenWidth, screenHeight);

      int score = 0;
      if (proximity == ProximityLevel.critical) {
        score += 100;
      } else if (proximity == ProximityLevel.caution) {
        score += 50;
      }

      if (region == ScreenRegion.center) {
        score += 80;
      } else {
        score += 20;
      }

      if (score > highestPriorityScore) {
        highestPriorityScore = score;
        highestPriorityObject = obj;
      }
    }

    final region =
        getScreenRegion(highestPriorityObject!.boundingBox, screenWidth);
    final proximity = getProximityLevel(
        highestPriorityObject.boundingBox, screenWidth, screenHeight);

    final List<String> labels = highestPriorityObject.labels
        .map((l) => l.text.toLowerCase())
        .toList();
    final String? topLabel = labels.isNotEmpty ? labels.first : null;

    final instruction = _buildInstruction(region, proximity, topLabel);
    final isCritical = proximity == ProximityLevel.critical &&
        region == ScreenRegion.center;

    return DetectionAnalysis(
      instruction: instruction,
      proximity: proximity,
      region: region,
      detectedLabel: topLabel,
      isCritical: isCritical,
    );
  }

  String _buildInstruction(
      ScreenRegion region, ProximityLevel proximity, String? label) {
    final String labelPart = label != null ? _formatLabel(label) : 'Obstacle';
    final String regionPart = _regionPhrase(region);
    final String proximityPart = _proximityPhrase(proximity);

    if (proximity == ProximityLevel.critical && region == ScreenRegion.center) {
      return 'Danger! $labelPart directly ahead. Stop immediately.';
    }

    if (proximity == ProximityLevel.critical) {
      return 'Danger! $labelPart very close on the ${_regionWord(region)}.';
    }

    if (proximity == ProximityLevel.caution) {
      return '$labelPart $regionPart $proximityPart.';
    }

    if (region == ScreenRegion.center) {
      return '$labelPart ahead, maintaining safe distance.';
    }

    return '$labelPart on the ${_regionWord(region)}, safe distance.';
  }

  String _formatLabel(String label) {
    if (label.isEmpty) return 'Object';
    return label[0].toUpperCase() + label.substring(1);
  }

  String _regionPhrase(ScreenRegion region) {
    switch (region) {
      case ScreenRegion.left:
        return 'on your left';
      case ScreenRegion.right:
        return 'on your right';
      case ScreenRegion.center:
        return 'ahead';
    }
  }

  String _regionWord(ScreenRegion region) {
    switch (region) {
      case ScreenRegion.left:
        return 'left';
      case ScreenRegion.right:
        return 'right';
      case ScreenRegion.center:
        return 'center';
    }
  }

  String _proximityPhrase(ProximityLevel proximity) {
    switch (proximity) {
      case ProximityLevel.safe:
        return 'at a safe distance';
      case ProximityLevel.caution:
        return 'approaching';
      case ProximityLevel.critical:
        return 'extremely close';
    }
  }

  InputImage _convertCameraImage(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final int numPlanes = image.planes.length;

    final InputImageRotation rotation = Platform.isAndroid
        ? InputImageRotation.rotation90deg
        : InputImageRotation.rotation0deg;

    if (Platform.isIOS) {
      final plane = image.planes[0];
      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(width.toDouble(), height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.bgra8888,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    }

    // Android NV21 handling: copy rows tightly into a new buffer to
    // eliminate per-plane stride padding. bytesPerRow then == width.
    final yPlane = image.planes[0];
    final int yBytesPerRow = yPlane.bytesPerRow;
    final int uvRowStride = numPlanes >= 2 ? image.planes[1].bytesPerRow : 0;
    final int uvPixelStride = numPlanes >= 2
        ? (image.planes[1].bytesPerPixel ?? 1)
        : 1;

    const int uvSampleSize = 2;
    final int uvWidth = (width + uvSampleSize - 1) ~/ uvSampleSize;
    final int uvHeight = (height + uvSampleSize - 1) ~/ uvSampleSize;
    final int ySize = width * height;
    final int uvSize = uvWidth * uvHeight * 2;

    final Uint8List bytes = Uint8List(ySize + uvSize);

    // Copy Y plane row-by-row, skipping stride padding
    for (int row = 0; row < height; row++) {
      final srcStart = row * yBytesPerRow;
      final dstStart = row * width;
      if (yBytesPerRow == width) {
        bytes.setRange(
          dstStart,
          dstStart + width,
          yPlane.bytes,
          srcStart,
        );
      } else {
        for (int col = 0; col < width; col++) {
          bytes[dstStart + col] = yPlane.bytes[srcStart + col];
        }
      }
    }

    if (numPlanes == 2) {
      // NV21: plane 1 is VU interleaved
      final vuPlane = image.planes[1];
      for (int row = 0; row < uvHeight; row++) {
        final srcStart = row * uvRowStride;
        final dstStart = ySize + row * uvWidth * 2;
        if (uvPixelStride == 2 && uvRowStride == uvWidth * 2) {
          bytes.setRange(
            dstStart,
            dstStart + uvWidth * 2,
            vuPlane.bytes,
            srcStart,
          );
        } else {
          for (int col = 0; col < uvWidth; col++) {
            final srcIdx = srcStart + col * uvPixelStride;
            bytes[dstStart + 2 * col] = vuPlane.bytes[srcIdx];
            bytes[dstStart + 2 * col + 1] = vuPlane.bytes[srcIdx + 1];
          }
        }
      }
    } else if (numPlanes >= 3) {
      // YUV420: separate U and V planes; interleave as VU for NV21
      final uPlane = image.planes[1];
      final vPlane = image.planes[2];
      final vRowStride = numPlanes >= 3 ? image.planes[2].bytesPerRow : 0;
      final vPixelStride = numPlanes >= 3
          ? (image.planes[2].bytesPerPixel ?? 1)
          : 1;
      for (int row = 0; row < uvHeight; row++) {
        final uSrcStart = row * uvRowStride;
        final vSrcStart = row * vRowStride;
        final dstStart = ySize + row * uvWidth * 2;
        for (int col = 0; col < uvWidth; col++) {
          bytes[dstStart + 2 * col] =
              vPlane.bytes[vSrcStart + col * vPixelStride];
          bytes[dstStart + 2 * col + 1] =
              uPlane.bytes[uSrcStart + col * uvPixelStride];
        }
      }
    }

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(width.toDouble(), height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: width,
      ),
    );
  }

  void dispose() {
    _detector.close();
  }
}
