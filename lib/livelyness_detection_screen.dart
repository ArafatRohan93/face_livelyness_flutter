

import 'dart:async';
import 'dart:math';

import 'package:camerawesome/camerawesome_plugin.dart' as cas;
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:demo_face_livelyness/index.dart';
import 'package:demo_face_livelyness/src/core/extensions/ml_kit_extentention.dart';
import 'package:demo_face_livelyness/src/core/models/captured_image.dart';
import 'package:demo_face_livelyness/src/core/models/face_detection_model.dart';
import 'package:demo_face_livelyness/src/screens/components/detection_widget.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';

class LivelynessDetectionScreen extends StatelessWidget {
  final LivelynessDetectionConfig config;

  const LivelynessDetectionScreen({
    required this.config,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LivelynessDetectionScreenV2(
          config: config,
        ),
      ),
    );
  }
}

class LivelynessDetectionScreenV2 extends StatefulWidget {
  final LivelynessDetectionConfig config;

  const LivelynessDetectionScreenV2({
    required this.config,
    super.key,
  });

  @override
  State<LivelynessDetectionScreenV2> createState() =>
      _LivelynessDetectionScreenAndroidState();
}

class _LivelynessDetectionScreenAndroidState
    extends State<LivelynessDetectionScreenV2> {
  //* MARK: - Private Variables
  //? =========================================================
  final _faceDetectionController = BehaviorSubject<FaceDetectionModel>();

  final options = FaceDetectorOptions(
    enableContours: true,
    enableClassification: true,
    enableTracking: true,
    enableLandmarks: true,
    performanceMode: FaceDetectorMode.accurate,
    minFaceSize: 0.05,
  );
  late final faceDetector = FaceDetector(options: options);
  bool _didCloseEyes = false;
  bool _isProcessingStep = false;

  late final List<LivelynessStepItem> _steps;
  final GlobalKey<LivelynessDetectionStepOverlayState> _stepsKey =
  GlobalKey<LivelynessDetectionStepOverlayState>();

  cas.CameraState? _cameraState;
  bool _isProcessing = false;
  late bool _isInfoStepCompleted;
  Timer? _timerToDetectFace;
  bool _isCaptureButtonVisible = false;
  bool _isCompleted = false;

  //* MARK: - Life Cycle Methods
  //? =========================================================
  @override
  void initState() {
    _preInitCallBack();
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
          (_) => _postFrameCallBack(),
    );
  }

  @override
  void deactivate() {
    faceDetector.close();
    super.deactivate();
  }

  @override
  void dispose() {
    _faceDetectionController.close();
    _timerToDetectFace?.cancel();
    _timerToDetectFace = null;
    super.dispose();
  }

  //* MARK: - Private Methods for Business Logic
  //? =========================================================
  void _preInitCallBack() {
    _steps = widget.config.steps;
    _isInfoStepCompleted = !widget.config.startWithInfoScreen;
  }

  void _postFrameCallBack() {
    if (_isInfoStepCompleted) {
      _startTimer();
    }
  }

  Future<void> _processCameraImage(AnalysisImage img) async {
    if (_isProcessing) {
      return;
    }
    if (mounted) {
      setState(
            () => _isProcessing = true,
      );
    }
    final inputImage = img.toInputImage();

    try {
      final List<Face> detectedFaces =
      await faceDetector.processImage(inputImage);
      _faceDetectionController.add(
        FaceDetectionModel(
          faces: detectedFaces,
          absoluteImageSize: inputImage.inputImageData!.size,
          rotation: 0,
          imageRotation: img.inputImageRotation,
          croppedSize: img.croppedSize,
        ),
      );
      await _processImage(inputImage, detectedFaces);
      if (mounted) {
        setState(
              () => _isProcessing = false,
        );
      }
    } catch (error) {
      if (mounted) {
        setState(
              () => _isProcessing = false,
        );
      }
      debugPrint("...sending image resulted error $error");
    }
  }

  Future<void> _processImage(InputImage img, List<Face> faces) async {
    try {
      if (faces.isEmpty) {
        _resetSteps();
        return;
      }
      final Face firstFace = faces.first;
      final landmarks = firstFace.landmarks;
      // Get landmark positions for relevant facial features
      final Point<int>? leftEye = landmarks[FaceLandmarkType.leftEye]?.position;
      final Point<int>? rightEye =
          landmarks[FaceLandmarkType.rightEye]?.position;
      final Point<int>? leftCheek =
          landmarks[FaceLandmarkType.leftCheek]?.position;
      final Point<int>? rightCheek =
          landmarks[FaceLandmarkType.rightCheek]?.position;
      final Point<int>? leftEar = landmarks[FaceLandmarkType.leftEar]?.position;
      final Point<int>? rightEar =
          landmarks[FaceLandmarkType.rightEar]?.position;
      final Point<int>? leftMouth =
          landmarks[FaceLandmarkType.leftMouth]?.position;
      final Point<int>? rightMouth =
          landmarks[FaceLandmarkType.rightMouth]?.position;

      // Calculate symmetry values based on corresponding landmark positions
      final Map<String, double> symmetry = {};
      final eyeSymmetry = calculateSymmetry(
        leftEye,
        rightEye,
      );
      symmetry['eyeSymmetry'] = eyeSymmetry;

      final cheekSymmetry = calculateSymmetry(
        leftCheek,
        rightCheek,
      );
      symmetry['cheekSymmetry'] = cheekSymmetry;

      final earSymmetry = calculateSymmetry(
        leftEar,
        rightEar,
      );
      symmetry['earSymmetry'] = earSymmetry;

      final mouthSymmetry = calculateSymmetry(
        leftMouth,
        rightMouth,
      );
      symmetry['mouthSymmetry'] = mouthSymmetry;
      double total = 0.0;
      symmetry.forEach((key, value) {
        total += value;
      });
      final double average = total / symmetry.length;
      print("Face Symmetry: $average");
      if (_isProcessingStep &&
          _steps[_stepsKey.currentState?.currentIndex ?? 0].step ==
              LivelynessCheckStep.blink) {
        if (_didCloseEyes) {
          if ((faces.first.leftEyeOpenProbability ?? 1.0) < 0.75 &&
              (faces.first.rightEyeOpenProbability ?? 1.0) < 0.75) {
            await _completeStep(
              step: _steps[_stepsKey.currentState?.currentIndex ?? 0].step,
            );
          }
        }
      }
      _detect(
        face: firstFace,
        step: _steps[_stepsKey.currentState?.currentIndex ?? 0].step,
      );
    } catch (e) {
      _startProcessing();
    }
  }

  Future<void> _completeStep({
    required LivelynessCheckStep step,
  }) async {
    final int indexToUpdate = _steps.indexWhere(
          (p0) => p0.step == step,
    );

    _steps[indexToUpdate] = _steps[indexToUpdate].copyWith(
      isCompleted: true,
    );
    if (mounted) {
      setState(() {});
    }
    await _stepsKey.currentState?.nextPage();
    _stopProcessing();
  }

  void _detect({
    required Face face,
    required LivelynessCheckStep step,
  }) async {
    switch (step) {
      case LivelynessCheckStep.blink:
        const double blinkThreshold = 0.25;
        if ((face.leftEyeOpenProbability ?? 1.0) < (blinkThreshold) &&
            (face.rightEyeOpenProbability ?? 1.0) < (blinkThreshold)) {
          _startProcessing();
          if (mounted) {
            setState(
                  () => _didCloseEyes = true,
            );
          }
        }
        break;
      case LivelynessCheckStep.turnLeft:
        const double headTurnThreshold = 45.0;
        if ((face.headEulerAngleY ?? 0) > (headTurnThreshold)) {
          _startProcessing();
          await _completeStep(step: step);
        }
        break;
      case LivelynessCheckStep.turnRight:
        const double headTurnThreshold = -45.0;
        if ((face.headEulerAngleY ?? 0) < (headTurnThreshold)) {
          _startProcessing();
          await _completeStep(step: step);
        }
        break;
      case LivelynessCheckStep.smile:
        const double smileThreshold = 0.75;
        if ((face.smilingProbability ?? 0) > (smileThreshold)) {
          _startProcessing();
          await _completeStep(step: step);
        }
        break;
    }
  }

  void _startProcessing() {
    if (!mounted) {
      return;
    }
    setState(
          () => _isProcessingStep = true,
    );
  }

  void _stopProcessing() {
    if (!mounted) {
      return;
    }
    setState(
          () => _isProcessingStep = false,
    );
  }

  void _startTimer() {
    _timerToDetectFace = Timer(
      Duration(seconds: widget.config.maxSecToDetect),
          () {
        _timerToDetectFace?.cancel();
        _timerToDetectFace = null;
        if (widget.config.allowAfterMaxSec) {
          _isCaptureButtonVisible = true;
          if (mounted) {
            setState(() {});
          }
          return;
        }
        _onDetectionCompleted(
          imgToReturn: null,
        );
      },
    );
  }

  Future<void> _takePicture({
    required bool didCaptureAutomatically,
  }) async {
    if (_cameraState == null) {
      _onDetectionCompleted();
      return;
    }
    _cameraState?.when(
      onPhotoMode: (p0) => Future.delayed(
        const Duration(milliseconds: 500),
            () => p0.takePhoto().then(
              (value) {
            _onDetectionCompleted(
              imgToReturn: value,
              didCaptureAutomatically: didCaptureAutomatically,
            );
          },
        ),
      ),
    );
  }

  void _onDetectionCompleted({
    String? imgToReturn,
    bool? didCaptureAutomatically,
  }) {
    if (_isCompleted) {
      return;
    }
    setState(
          () => _isCompleted = true,
    );
    final String imgPath = imgToReturn ?? "";
    if (imgPath.isEmpty || didCaptureAutomatically == null) {
      Navigator.of(context).pop(null);
      return;
    }
    Navigator.of(context).pop(
      CapturedImage(
        imgPath: imgPath,
        didCaptureAutomatically: didCaptureAutomatically,
      ),
    );
  }

  void _resetSteps() async {
    for (var p0 in _steps) {
      final int index = _steps.indexWhere(
            (p1) => p1.step == p0.step,
      );
      _steps[index] = _steps[index].copyWith(
        isCompleted: false,
      );
    }
    _didCloseEyes = false;
    if (_stepsKey.currentState?.currentIndex != 0) {
      _stepsKey.currentState?.reset();
    }
    if (mounted) {
      setState(() {});
    }
  }

  //* MARK: - Private Methods for UI Components
  //? =========================================================
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        _isInfoStepCompleted
            ? cas.CameraAwesomeBuilder.custom(
          flashMode: cas.FlashMode.auto,
          previewFit: cas.CameraPreviewFit.contain,
          aspectRatio: cas.CameraAspectRatios.ratio_16_9,
          sensor: cas.Sensors.front,
          onImageForAnalysis: (img) => _processCameraImage(img),
          imageAnalysisConfig: cas.AnalysisConfig(
            autoStart: true,
            androidOptions: const cas.AndroidAnalysisOptions.nv21(
              width: 250,
            ),
            maxFramesPerSecond: 30,
          ),
          builder: (state, previewSize, previewRect) {
            _cameraState = state;
            return PreviewDecoratorWidget(
              cameraState: state,
              faceDetectionStream: _faceDetectionController,
              previewSize: previewSize,
              previewRect: previewRect,
              detectionColor:
              _steps[_stepsKey.currentState?.currentIndex ?? 0]
                  .detectionColor,
            );
          },
          saveConfig: SaveConfig.photo(
            pathBuilder: () async {
              final String fileName = "${Utils.generate()}.jpg";
              final String path = await getTemporaryDirectory().then(
                    (value) => value.path,
              );
              return "$path/$fileName";
            },
          ),
        )
            : LivelynessInfoWidget(
          onStartTap: () {
            if (!mounted) {
              return;
            }
            _startTimer();
            setState(
                  () => _isInfoStepCompleted = true,
            );
          },
        ),
        if (_isInfoStepCompleted)
          LivelynessDetectionStepOverlay(
            key: _stepsKey,
            steps: _steps,
            onCompleted: () => _takePicture(
              didCaptureAutomatically: true,
            ),
          ),
        Visibility(
          visible: _isCaptureButtonVisible,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Spacer(
                flex: 20,
              ),
              MaterialButton(
                onPressed: () => _takePicture(
                  didCaptureAutomatically: false,
                ),
                color: widget.config.captureButtonColor ??
                    Theme.of(context).primaryColor,
                textColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shape: const CircleBorder(),
                child: const Icon(
                  Icons.camera_alt,
                  size: 24,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(
              right: 10,
              top: 10,
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.black,
              child: IconButton(
                onPressed: () {
                  _onDetectionCompleted(
                    imgToReturn: null,
                    didCaptureAutomatically: null,
                  );
                },
                icon: const Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  double calculateSymmetry(
      Point<int>? leftPosition, Point<int>? rightPosition) {
    if (leftPosition != null && rightPosition != null) {
      final double dx = (rightPosition.x - leftPosition.x).abs().toDouble();
      final double dy = (rightPosition.y - leftPosition.y).abs().toDouble();
      final distance = Offset(dx, dy).distance;

      return distance;
    }

    return 0.0;
  }
}
