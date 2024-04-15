
import 'package:demo_face_livelyness/index.dart';

class MLHelper {
  //* MARK: - Converting class to Singleton
  //? =========================================================
  MLHelper._privateConstructor();
  static final MLHelper instance = MLHelper._privateConstructor();

  //* MARK: - Public Variables
  //? =========================================================
  final FaceDetector faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      enableLandmarks: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  //* MARK: - Public Methods
  //? =========================================================
  Future<List<Face>> processInputImage(InputImage imgFile) async {
    for (var i = 0; i < 3; i++) {
      final List<Face> faces = await faceDetector.processImage(
        imgFile,
      );
      if (faces.isNotEmpty) {
        return faces;
      }
    }
    return [];
  }
}