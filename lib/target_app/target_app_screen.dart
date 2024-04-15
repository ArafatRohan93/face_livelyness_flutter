import 'dart:async';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:demo_face_livelyness/face_detection_camera_view.dart';
import 'package:flutter/material.dart';

import '../src/core/enums/livelyness_step.dart';
import '../src/core/models/livelyness_step_item.dart';
import 'face_recognition_mode.dart';

class TargetAppScreen extends StatefulWidget {
  const TargetAppScreen({Key? key}) : super(key: key);

  @override
  State<TargetAppScreen> createState() => _TargetAppScreenState();
}

class _TargetAppScreenState extends State<TargetAppScreen> {
  CameraController? _cameraController;
  bool isInTime = true;
  List<CameraDescription> cameras = [];
  late StreamSubscription _addAttendanceBlocStream;

  late List<double> predictedData;

  @override
  void initState() {
    super.initState();
    getCameraList().then((value) {
      setState(() {});
    });
  }

  Future<void> getCameraList() async {
    try {
      cameras = await availableCameras();
    } catch (e) {
      print('Error on getCameraList() with $e');
    }
  }

/*  void listenAddAttendanceBloc() {
    _addAttendanceBlocStream =
        context.read<AddFaceAttendanceBloc>().stream.listen((state) async {
          if (state is AddFaceAttendanceSuccessState) {
            if ((_cameraController?.value.isInitialized ?? false) &&
                (_cameraController?.value.isPreviewPaused ?? false)) {
              await _cameraController!.resumePreview();
              if (mounted) {
                SnackMessage.showToast(
                    context, state.success.message, SnackMessageType.success);
              }
            }
          } else if (state is AddFaceAttendanceFailedState) {
            if ((_cameraController?.value.isInitialized ?? false) &&
                (_cameraController?.value.isPreviewPaused ?? false)) {
              await _cameraController!.resumePreview();
              if (mounted) {
                SnackMessage.showToast(
                    context, state.messageData.message, SnackMessageType.error);
              }
            }
          }
        });
  }*/

  final List<LivelynessStepItem> _stepsList = [
    LivelynessStepItem(
      step: LivelynessCheckStep.blink,
      title: "Blink",
      isCompleted: false,
      detectionColor: Colors.amber,
    ),
    LivelynessStepItem(
      step: LivelynessCheckStep.smile,
      title: "Smile",
      isCompleted: false,
      detectionColor: Colors.green.shade800,
    ),
    LivelynessStepItem(
      step: LivelynessCheckStep.turnLeft,
      title: "Turn Left",
      isCompleted: false,
      detectionColor: Colors.green.shade800,
    ),
    LivelynessStepItem(
      step: LivelynessCheckStep.turnRight,
      title: "Turn Right",
      isCompleted: false,
      detectionColor: Colors.green.shade800,
    ),
  ];

  List<T> shuffleList<T>(List<T> inputList) {
    // Create a copy of the input list to avoid modifying the original list
    List<T> shuffledList = List.from(inputList);

    // Use the Fisher-Yates shuffle algorithm to shuffle the list
    final Random random = Random();
    for (int i = shuffledList.length - 1; i > 0; i--) {
      int j = random.nextInt(i + 1);
      T temp = shuffledList[i];
      shuffledList[i] = shuffledList[j];
      shuffledList[j] = temp;
    }

    return shuffledList;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          SizedBox(height: 16),
          Visibility(
            visible: cameras.isNotEmpty,
            replacement: const Center(
              child: CircularProgressIndicator(),
            ),
            child: Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  children: [
                    FaceRecognitionCameraViewScreen(
                      livelynessCheckStep: shuffleList(_stepsList),
                      cameras: cameras,
                      faceRecognitionMode: FaceRecognitionMode.live,
                      viewMode: ViewMode.recognition,
                      onMatch: (employeeId, employeeName, cameraController) {
                        _cameraController = cameraController;
                        addAttendance(employeeId, employeeName);
                      },
                    ),
                  ],
                ),
              ),

              /*BlocBuilder<GetFaceAttendancePointsBloc,
                  GetFaceAttendancePointsState>(
                builder: (context, state) {
                */ /*  if (state is GetFaceAttendancePointsLoadingState) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }*/ /*
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Stack(
                      children: [
                        FaceRecognitionCameraViewScreen(
                          cameras: cameras,
                          faceRecognitionMode: FaceRecognitionMode.live,
                          viewMode: ViewMode.recognition,
                          onMatch:
                              (employeeId, employeeName, cameraController) {
                            _cameraController = cameraController;
                            addAttendance(employeeId, employeeName);
                          },
                        ),
                        */ /*     BlocBuilder<AddFaceAttendanceBloc,
                          AddFaceAttendanceState>(builder: (context, state) {
                        if (state is AddFaceAttendanceLoadingState) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        return const SizedBox();
                      })*/ /*
                      ],
                    ),
                  );
                },
              ),*/
            ),
          )
        ],
      ),
    );
  }

  Future<void> addAttendance(int employeeId, String? employeeName) async {
    if (_cameraController?.value.isInitialized ?? false) {
      await _cameraController!.pausePreview();
    }
    // bool isUsingFakeGps = await GeoLocatorUtils.isUsingFakeGps();
    if (!mounted) return;
    /*   if (isUsingFakeGps) {
      if ((_cameraController?.value.isInitialized ?? false) &&
          (_cameraController?.value.isPreviewPaused ?? false)) {
        await _cameraController!.resumePreview();
      }
      if (!mounted) return;
      SnackMessage.showToast(
          context, context.localization.turn_off_fake_gps_to_proceed);
    } else {*/
    print('@@@@@@@@@@@@@@@_____________hiiiiiiii________________@@@@@@@@@@@@@');
/*      LocationService.getLocationWithHandler(context).then((position) {
        if (position != null && mounted) {
          context.read<AddFaceAttendanceBloc>().add(
            AddFaceAttendanceProceedEvent(isInTime, employeeId,
                employeeName, position.latitude, position.longitude),
          );
        }
      });*/
    // }
  }

  @override
  void dispose() {
    if (_cameraController?.value.isInitialized ?? false) {
      _cameraController!.dispose();
    }
    super.dispose();
  }
}
