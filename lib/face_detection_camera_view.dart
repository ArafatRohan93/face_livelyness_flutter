import 'dart:io';

import 'package:camera/camera.dart';
import 'package:demo_face_livelyness/src/core/enums/livelyness_step.dart';
import 'package:demo_face_livelyness/src/core/models/livelyness_step_item.dart';
import 'package:demo_face_livelyness/target_app/employee_face_data.dart';
import 'package:demo_face_livelyness/target_app/eulidean_distance.dart';
import 'package:demo_face_livelyness/target_app/face_detector_painter.dart';
import 'package:demo_face_livelyness/target_app/face_recognition_mode.dart';
import 'package:demo_face_livelyness/target_app/image_processing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tflite;
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceRecognitionCameraViewScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final List<LivelynessStepItem> livelynessCheckStep;
  final FaceRecognitionMode faceRecognitionMode;
  final ViewMode viewMode;
  final Function(XFile image, List<double> inputData)? onCapture;
  final Function(int employeeId, String? employeeName,
      CameraController cameraController)? onMatch;
  final List<double>? givenPredictedData;

  const FaceRecognitionCameraViewScreen(
      {Key? key,
      required this.cameras,
      required this.faceRecognitionMode,
      required this.viewMode,
      required this.livelynessCheckStep,
      this.onCapture,
      this.onMatch,
      this.givenPredictedData})
      : super(key: key);

  @override
  State<FaceRecognitionCameraViewScreen> createState() =>
      _FaceRecognitionCameraViewScreenState();
}

class _FaceRecognitionCameraViewScreenState
    extends State<FaceRecognitionCameraViewScreen> with WidgetsBindingObserver {
  late CameraController _cameraController;
  int _selectedCamera = 1;
  late CameraImage cameraImg;
  XFile? capturedImage;
  bool isLivelynessChecked = false;

  late final List<LivelynessStepItem> _livelynessCheckSteps =
      widget.livelynessCheckStep;

  bool isBusy = false;
  ValueNotifier<CustomPaint?> customPaint = ValueNotifier(null);
  List<Face> facesList = [];
  bool eyeBlinking = false;
  bool eyeOpen = false;
  bool eyeClose = false;
  late Interpreter interpreter;
  double threshold = 1.0;
  late List<bool> _livelynessStatusList;
  late LivelynessStepItem _currentStep = widget.livelynessCheckStep.first;
  int _currentCheckIndex = 0;
  bool isAllDone = false;

  List<double> predictedData = [];
  FaceDetector faceDetector =
      GoogleMlKit.vision.faceDetector(const FaceDetectorOptions(
    enableContours: true,
    mode: FaceDetectorMode.accurate,
    enableClassification: true,
  ));

  // final VLogger _vLogger = di<VLogger>();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startLiveFeed();
    } else if (state == AppLifecycleState.inactive) {
      _stopLiveFeed();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _livelynessStatusList =
        List.filled(widget.livelynessCheckStep.length, false, growable: true);
    loadTFLiteModel();
    _initializeCameraController();
  }

  /// load tensor flow lite model
  Future<void> loadTFLiteModel() async {
    try {
      var interpreterOptions = tflite.InterpreterOptions();
      interpreter = await tflite.Interpreter.fromAsset('mobilefacenet.tflite',
          options: interpreterOptions);
    } catch (e) {
      print('Failed to load tflite model with error ${e.toString()}');
    }
  }

  void _initializeCameraController() {
    _cameraController = CameraController(
      widget.cameras[_selectedCamera],
      ResolutionPreset.high,
      enableAudio: false,
    );
    _cameraController.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
      _startLiveFeed();
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            break;
          default:
            break;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 90,
          ),
          Visibility(
            visible: widget.faceRecognitionMode == FaceRecognitionMode.manual,
            child: FloatingActionButton(
              heroTag: 'capture-camera',
              onPressed: _captureLiveCamera,
              child: const Icon(Icons.camera),
            ),
          ),
          Visibility(
            child: SizedBox(
              height: 50,
              width: 50,
              child: FloatingActionButton(
                heroTag: 'toggle-camera',
                backgroundColor: Colors.orange,
                onPressed: _toggleCamera,
                child: Icon(
                  Icons.cameraswitch,
                  size: 24,
                ),
              ),
            ),
          )
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(
            _cameraController,
          ),
          Container(
            height: 300,
            color: Colors.transparent,
            padding: const EdgeInsets.all(16),
            child: Text(
              isAllDone ? 'Done' : (isLivelynessChecked ? 'Blink Now' : _currentStep.title),
              style: TextStyle(color: Colors.black, fontSize: 30),
            ),
          ),
          ValueListenableBuilder(
              valueListenable: customPaint,
              builder: (context, point, _) {
                final CustomPaint? p = point as CustomPaint?;
                return Visibility(
                  visible: p != null,
                  child: p ?? const SizedBox(),
                );
              }),
        ],
      ),
    );
  }

  void _toggleCamera() {
    if (widget.cameras.length > 1) {
      if (_selectedCamera == 0) {
        _selectedCamera = 1;
      } else if (_selectedCamera == 1) {
        _selectedCamera = 0;
      }
      _initializeCameraController();
    }
  }

  Future _startLiveFeed() async {
    try {
      final camera = widget.cameras[_selectedCamera];
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      _cameraController.initialize().then((_) {
        if (!mounted) {
          return;
        }
        if (widget.faceRecognitionMode == FaceRecognitionMode.live) {
          _cameraController.startImageStream(_processCameraImage);
        }
        setState(() {});
      });
    } on Exception catch (e) {
      print('Error on _startLiveFeed() with $e');
    }
  }

  Future _captureLiveCamera() async {
    if (_cameraController.value.isTakingPicture == false) {
      await _cameraController.takePicture().then((picture) async {
        final inputImage = InputImage.fromFilePath(picture.path);
        CameraLensDirection cameraLensDirection =
            widget.cameras[_selectedCamera].lensDirection;
        await processCapturedImageFile(picture, inputImage, cameraLensDirection)
            .then((_) {
          if (predictedData.isNotEmpty) {
            if (widget.viewMode == ViewMode.capture) {
              widget.onCapture!(picture, predictedData);
              predictedData = [];
            } else {
              bool matched = checkSingleEmployeeMatchORNot(predictedData);
              if (matched) {
                if (widget.onMatch != null) {
                  widget.onMatch!(-1, null, _cameraController);
                  widget.onCapture!(picture, predictedData);
                  predictedData = [];
                }
              } else {
                /*   if (mounted) {
                  SnackMessage.showToast(
                      context,
                      context.localization.face_not_matched,
                      SnackMessageType.error);
                }*/
                resetDetectionCriteria();
              }
            }
          }
        });
      });
    }
  }

  Future<void> processCapturedImageFile(XFile imageFile, InputImage inputImage,
      CameraLensDirection cameraLensDirection) async {
    if (isBusy) return;
    isBusy = true;
    final faces = await faceDetector.processImage(inputImage);
    if (faces.isEmpty) {
      //21339
      isBusy = false;
      return;
    }

    if (inputImage.inputImageData?.size != null &&
        inputImage.inputImageData?.imageRotation != null) {
      final painter = FaceDetectorPainter(
          faces,
          inputImage.inputImageData!.size,
          inputImage.inputImageData!.imageRotation);
      customPaint.value = CustomPaint(painter: painter);
    } else {
      customPaint.value = null;
    }
    isBusy = false;
    if (mounted) {
      setState(() {
        facesList = faces;
      });
      if (faces.isNotEmpty) {
        await getCurrentPredictionForCapturedImage(
            imageFile, faces[0], cameraLensDirection);
      } else {
        print('No face detected! Please blink your eyes');
      }
    }
  }

  Future<List<double>> getCurrentPredictionForCapturedImage(XFile imageFile,
      Face face, CameraLensDirection cameraLensDirection) async {
    try {
      /// crops the face from the image and transforms it to an array of data
      List input =
          await ImageProcessing.preProcessFile(File(imageFile.path), face);

      /// then reshapes input and output to model format 🧑‍🔧
      input = input.reshape([1, 112, 112, 3]);
      List output = List.generate(1, (index) => List.filled(192, 0));

      /// runs and transforms the data 🤖
      interpreter.run(input, output);
      output = output.reshape([192]);

      predictedData = List.from(output);
      return predictedData;
    } catch (e) {
      print('Error on getCurrentPredictionForCapturedImage() with $e');
      return [];
    }
  }

  Future _processCameraImage(CameraImage image) async {
    cameraImg = image;
    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize =
        Size(image.width.toDouble(), image.height.toDouble());

    final camera = widget.cameras[_selectedCamera];

    final imageRotation =
        InputImageRotationMethods.fromRawValue(camera.sensorOrientation) ??
            InputImageRotation.Rotation_0deg;

    final inputImageFormat =
        InputImageFormatMethods.fromRawValue(image.format.raw) ??
            InputImageFormat.NV21;

    final planeData = image.planes.map(
      (Plane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      },
    ).toList();

    final inputImageData = InputImageData(
      size: imageSize,
      imageRotation: imageRotation,
      inputImageFormat: inputImageFormat,
      planeData: planeData,
    );

    final inputImage =
        InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);
    processLiveFeedImage(inputImage, cameraImg, camera.lensDirection);
  }

  Future<void> processLiveFeedImage(InputImage inputImage,
      CameraImage cameraImg, CameraLensDirection lensDirection) async {
    if (isBusy) return;
    isBusy = true;
    final faces = await faceDetector.processImage(inputImage);
    if (inputImage.inputImageData?.size != null &&
        inputImage.inputImageData?.imageRotation != null) {
      final painter = FaceDetectorPainter(
          faces,
          inputImage.inputImageData!.size,
          inputImage.inputImageData!.imageRotation);
      customPaint.value = CustomPaint(painter: painter);
    } else {
      customPaint.value = null;
    }
    isBusy = false;
    if (mounted) {
      facesList = faces;
      if (facesList.isNotEmpty) {
        if (!isLivelynessChecked) {
          checkLivelyness(facesList.first, _currentStep);
        } else {
          if (facesList.first.leftEyeOpenProbability! < 0.15 &&
              facesList.first.rightEyeOpenProbability! < 0.15) {
            eyeClose = true;
          } else {
            eyeOpen = true;
          }
          if (eyeOpen && eyeClose) {
            eyeBlinking = true;
            if (facesList.isNotEmpty) {
              print('-------------------blinked eye-------------------');
              isBusy = true;
              isAllDone = true;
              setState(() {});
              // setCurrentPrediction(cameraImg, lensDirection, facesList[0]);
            }
          }
        }
      }

/*      if (facesList.isNotEmpty &&
          facesList[0].leftEyeOpenProbability != null &&
          facesList[0].rightEyeOpenProbability != null) {
        if (facesList[0].leftEyeOpenProbability! < 0.15 &&
            facesList[0].rightEyeOpenProbability! < 0.15) {
          eyeClose = true;
        } else {
          eyeOpen = true;
        }
      }
      if (eyeOpen && eyeClose) {
        eyeBlinking = true;
        if (facesList.isNotEmpty) {
          print('-------------------blinked eye-------------------');
          isBusy = false;
          // setCurrentPrediction(cameraImg, lensDirection, facesList[0]);
        }
      }*/
    }
  }

  checkLivelyness(Face face, LivelynessStepItem step) {
    switch (step.step) {
      case LivelynessCheckStep.smile:
        if ((face.smilingProbability ?? 0) > (step.thresholdToCheck ?? 0.75)) {
          goToNextStep();
        }
        break;
      case LivelynessCheckStep.blink:
        if (facesList.isNotEmpty &&
            facesList[0].leftEyeOpenProbability != null &&
            facesList[0].rightEyeOpenProbability != null) {
          if (facesList[0].leftEyeOpenProbability! < 0.15 &&
              facesList[0].rightEyeOpenProbability! < 0.15) {
            eyeClose = true;
          } else {
            eyeOpen = true;
          }
        }
        if (eyeOpen && eyeClose) {
          eyeBlinking = true;
          goToNextStep();
        }
        break;
      case LivelynessCheckStep.turnLeft:
        const double headTurnThreshold = 45.0;
        if ((face.headEulerAngleY ?? 0) > (headTurnThreshold)) {
          goToNextStep();
        }
        break;
      case LivelynessCheckStep.turnRight:
        const double headTurnThreshold = -45.0;
        if ((face.headEulerAngleY ?? 0) < (headTurnThreshold)) {
          goToNextStep();
        }
        break;
    }
  }

  goToNextStep() {
    _livelynessStatusList[_currentCheckIndex] = true;
    isBusy = false;
    if (_currentCheckIndex != _livelynessCheckSteps.length - 1) {
      _currentCheckIndex++;
      _currentStep = _livelynessCheckSteps[_currentCheckIndex];
    } else {
      isLivelynessChecked = true;
      eyeClose = false;
      eyeOpen = false;
      eyeBlinking = false;
    }
    setState(() {});
  }

  Future<void> setCurrentPrediction(
    CameraImage cameraImage,
    CameraLensDirection cameraLensDirection,
    Face face,
  ) async {
    try {
      /// crops the face from the image and transforms it to an array of data
      List input = ImageProcessing.preProcess(cameraImage, face);

      /// then reshapes input and ouput to model format 🧑‍🔧
      input = input.reshape([1, 112, 112, 3]);
      List output = List.generate(1, (index) => List.filled(192, 0));

      /// runs and transforms the data 🤖
      interpreter.run(input, output);
      output = output.reshape([192]);

      predictedData = List.from(output);
/*      // Automatic
      EmployeeFaceData? matchedEmployee =
          await checkEmployeeFaceMatchedOrNot(predictedData);
      if (matchedEmployee != null) {
        if (widget.onMatch != null) {
          widget.onMatch!(
            matchedEmployee.employeeId,
            matchedEmployee.name,
            _cameraController,
          );
        }
      } else {
        resetDetectionCriteria();
      }*/
      resetDetectionCriteria();
    } catch (e) {
      print('Error on setCurrentPrediction() with $e');
    }
  }

  /// check if the user matched to local database users
  // TODO : Calculation update @mustafiz_vai
  Future<EmployeeFaceData?> checkEmployeeFaceMatchedOrNot(
      List<double> employeeFaceData) async {
/*    final selectedEmployee =
        await EmployeeFaceRecognitionLocalDatabaseService(di<DbHelper>())
            .validateEmployeeFaceData(employeeFaceData);
    if (selectedEmployee != null) {
      debugPrint(
          'Detection accuracy ${selectedEmployee.name}, ${selectedEmployee.result}');
    }
    if (selectedEmployee != null && selectedEmployee.result <= 0.7) {
      return selectedEmployee;
    } else {
      return null;
    }*/
  }

  bool checkSingleEmployeeMatchORNot(List<double> employeeFaceData) {
    final result =
        euclideanDistance(widget.givenPredictedData!, employeeFaceData);
    if (result <= 0.7) {
      return true;
    } else {
      return false;
    }
  }

  void resetDetectionCriteria() {
    isBusy = false;
    eyeBlinking = false;
    eyeClose = false;
    eyeOpen = false;
  }

  Future _stopLiveFeed() async {
    if (_cameraController.value.isInitialized) {
      if (_cameraController.value.isStreamingImages) {
        await _cameraController.stopImageStream();
      }
      await _cameraController.dispose();
    }
  }

  @override
  void dispose() {
    _stopLiveFeed();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
