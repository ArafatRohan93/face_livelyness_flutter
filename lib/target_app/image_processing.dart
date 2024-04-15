import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as imglib;

class ImageProcessing {
  static List preProcess(CameraImage image, Face faceDetected) {
    // crops the face 💇
    try {
      imglib.Image croppedImage = cropFace(image, faceDetected);
      imglib.Image img = imglib.copyResizeCropSquare(
        croppedImage,
        size: 112,
      );

      // transforms the cropped face to array data
      Float32List imageAsList = imageToByteListFloat32(img);
      return imageAsList;
    } on Exception catch (e) {
      print('Error on preProcess() with $e');
    }
    return [];
  }

  static Future<List> preProcessFile(File image, Face faceDetected) async {
    // crops the face 💇
    imglib.Image croppedImage = await cropFaceFile(image, faceDetected);
    imglib.Image img = imglib.copyResizeCropSquare(croppedImage, size: 112);

    // transforms the cropped face to array data
    Float32List imageAsList = imageToByteListFloat32(img);
    return imageAsList;
  }

  static Float32List imageToByteListFloat32(imglib.Image image) {
    /// input size = 112
    var convertedBytes = Float32List(1 * 112 * 112 * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (var i = 0; i < 112; i++) {
      for (var j = 0; j < 112; j++) {
        var pixel = image.getPixel(j, i);

        /// mean: 128
        /// std: 128
        buffer[pixelIndex++] = (pixel.r - 128) / 128;
        buffer[pixelIndex++] = (pixel.g - 128) / 128;
        buffer[pixelIndex++] = (pixel.b - 128) / 128;
      }
    }
    return convertedBytes.buffer.asFloat32List();
  }

  static imglib.Image cropFace(CameraImage image, Face faceDetected) {
    imglib.Image convertedImage = convertCameraImage(image);
    double x = faceDetected.boundingBox.left - 10.0;
    double y = faceDetected.boundingBox.top - 10.0;
    double w = faceDetected.boundingBox.width + 10.0;
    double h = faceDetected.boundingBox.height + 10.0;
    return imglib.copyCrop(convertedImage,
        x: x.round(), y: y.round(), width: w.round(), height: h.round());
  }

  static Future<imglib.Image> cropFaceFile(
      File image, Face faceDetected) async {
    var bytes = await File(image.path).readAsBytes();
    imglib.Image convertedImage = imglib.decodeImage(bytes)!;
    double x = faceDetected.boundingBox.left - 10.0;
    double y = faceDetected.boundingBox.top - 10.0;
    double w = faceDetected.boundingBox.width + 10.0;
    double h = faceDetected.boundingBox.height + 10.0;
    return imglib.copyCrop(convertedImage,
        x: x.round(), y: y.round(), width: w.round(), height: h.round());
  }

  static imglib.Image convertCameraImage(CameraImage image) {
    int width = image.width;
    int height = image.height;
    var img = imglib.Image(width: width, height: height);
    const int hexFF = 0xFF000000;
    final int uvyButtonStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel!;
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        final int uvIndex =
            uvPixelStride * (x / 2).floor() + uvyButtonStride * (y / 2).floor();
        final int index = y * width + x;
        final yp = image.planes[0].bytes[index];
        final up = image.planes[1].bytes[uvIndex];
        final vp = image.planes[2].bytes[uvIndex];
        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
            .round()
            .clamp(0, 255);
        int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
        img.data!.buffer.asUint32List()[index] =
            hexFF | (b << 16) | (g << 8) | r;
      }
    }
    var img1 = imglib.copyRotate(img, angle: -90);
    return img1;
  }

  static imglib.Image convertCameraImageToImage(
      CameraImage image, CameraLensDirection cameraLensDirection) {
    int width = image.width;
    int height = image.height;
    var img = imglib.Image(width: width, height: height);
    const int hexFF = 0xFF000000;
    final int uvyButtonStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel!;
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        final int uvIndex =
            uvPixelStride * (x / 2).floor() + uvyButtonStride * (y / 2).floor();
        final int index = y * width + x;
        final yp = image.planes[0].bytes[index];
        final up = image.planes[1].bytes[uvIndex];
        final vp = image.planes[2].bytes[uvIndex];
        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
            .round()
            .clamp(0, 255);
        int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
        img.data!.buffer.asUint32List()[index] =
            hexFF | (b << 16) | (g << 8) | r;
      }
    }
    imglib.Image finalImage;
    if (cameraLensDirection == CameraLensDirection.back) {
      finalImage = imglib.copyRotate(img, angle: 90);
    } else {
      finalImage = imglib.copyRotate(img, angle: -90);
    }
    return finalImage;
  }
}
