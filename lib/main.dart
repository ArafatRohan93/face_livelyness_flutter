import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:demo_face_livelyness/livelyness_detection.dart';
import 'package:demo_face_livelyness/target_app/target_app_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'index.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    home: TargetAppScreen1(),
  ));
}

class TargetAppScreen1 extends StatefulWidget {
  const TargetAppScreen1({Key? key}) : super(key: key);

  @override
  State<TargetAppScreen1> createState() => _TargetAppScreen1State();
}

class _TargetAppScreen1State extends State<TargetAppScreen1> {
  late List<CameraDescription> cameras;

  @override
  void initState() {
    super.initState();
    getCameraList().then((_) => setState(() {}));
  }

  Future<void> getCameraList() async {
    try {
      cameras = await availableCameras();
    } catch (e) {
      print('Error on getCameraList() with $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TargetAppScreen(),
                ));
          },
          child: Text('Press'),
        ),
      ),
    );
  }
}

class ExpampleScreen extends StatefulWidget {
  const ExpampleScreen({super.key});

  @override
  State<ExpampleScreen> createState() => _ExpampleScreenState();
}

class _ExpampleScreenState extends State<ExpampleScreen> {
  //* MARK: - Private Variables
  //? =========================================================
  String? _capturedImagePath;
  final bool _isLoading = false;
  bool _startWithInfo = false;
  bool _allowAfterTimeOut = false;
  final List<LivelynessStepItem> _veificationSteps = [];
  int _timeOutDuration = 30;

  //* MARK: - Life Cycle Methods
  //? =========================================================
  @override
  void initState() {
    _initValues();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  //* MARK: - Private Methods for Business Logic
  //? =========================================================
  void _initValues() {
    _veificationSteps.addAll(
      [
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
      ],
    );
    LivelynessDetection.instance.configure(
      lineColor: Colors.white,
      dotColor: Colors.purple.shade800,
      dotSize: 2.0,
      lineWidth: 2,
      dashValues: [2.0, 5.0],
      displayDots: true,
      displayLines: false,
      thresholds: [
        SmileDetectionThreshold(
          probability: 0.8,
        ),
        BlinkDetectionThreshold(
          leftEyeProbability: 0.25,
          rightEyeProbability: 0.25,
        ),
      ],
    );
  }

  void _onStartLivelyness() async {
    setState(() => _capturedImagePath = null);
    final dynamic response =
        await LivelynessDetection.instance.detectLivelyness(
      context,
      config: LivelynessDetectionConfig(
        steps: shuffleList<LivelynessStepItem>(_veificationSteps),
        startWithInfoScreen: _startWithInfo,
        maxSecToDetect: _timeOutDuration == 100 ? 2500 : _timeOutDuration,
        allowAfterMaxSec: _allowAfterTimeOut,
        captureButtonColor: Colors.red,
      ),
    );
    if (response == null) {
      return;
    }
    setState(
      () => _capturedImagePath = response.imgPath,
    );
  }

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

  String _getTitle(LivelynessCheckStep step) {
    switch (step) {
      case LivelynessCheckStep.blink:
        return "Blink";
      case LivelynessCheckStep.turnLeft:
        return "Turn Your Head Left";
      case LivelynessCheckStep.turnRight:
        return "Turn Your Head Right";
      case LivelynessCheckStep.smile:
        return "Smile";
    }
  }

  String _getSubTitle(LivelynessCheckStep step) {
    switch (step) {
      case LivelynessCheckStep.blink:
        return "Detects Blink on the face visible in camera";
      case LivelynessCheckStep.turnLeft:
        return "Detects Left Turn of the on the face visible in camera";
      case LivelynessCheckStep.turnRight:
        return "Detects Right Turn of the on the face visible in camera";
      case LivelynessCheckStep.smile:
        return "Detects Smile on the face visible in camera";
    }
  }

  bool _isSelected(LivelynessCheckStep step) {
    final LivelynessStepItem? doesExist = _veificationSteps.firstWhereOrNull(
      (p0) => p0.step == step,
    );
    return doesExist != null;
  }

  void _onStepValChanged(LivelynessCheckStep step, bool value) {
    if (!value && _veificationSteps.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Need to have atleast 1 step of verification",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          backgroundColor: Colors.red.shade900,
        ),
      );
      return;
    }
    final LivelynessStepItem? doesExist = _veificationSteps.firstWhereOrNull(
      (p0) => p0.step == step,
    );

    if (doesExist == null && value) {
      _veificationSteps.add(
        LivelynessStepItem(
          step: step,
          title: _getTitle(step),
          isCompleted: false,
        ),
      );
    } else {
      if (!value) {
        _veificationSteps.removeWhere(
          (p0) => p0.step == step,
        );
      }
    }
    setState(() {});
  }

  //* MARK: - Private Methods for UI Components
  //? =========================================================
  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        " Livelyness Detection",
      ),
    );
  }

  Widget _buildBody() {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildContent(),
        Visibility(
          visible: _isLoading,
          child: const Center(
            child: CircularProgressIndicator.adaptive(),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Spacer(
          flex: 4,
        ),
        Visibility(
          visible: _capturedImagePath != null,
          child: Expanded(
            flex: 7,
            child: Image.file(
              File(_capturedImagePath ?? ""),
              fit: BoxFit.contain,
            ),
          ),
        ),
        Visibility(
          visible: _capturedImagePath != null,
          child: const Spacer(),
        ),
        Center(
          child: ElevatedButton(
            onPressed: _onStartLivelyness,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 20,
              ),
            ),
            child: const Text(
              "Detect Livelyness",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Spacer(
              flex: 3,
            ),
            const Text(
              "Start with info screen:",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            CupertinoSwitch(
              value: _startWithInfo,
              onChanged: (value) => setState(
                () => _startWithInfo = value,
              ),
            ),
            const Spacer(
              flex: 3,
            ),
          ],
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Spacer(
              flex: 3,
            ),
            const Text(
              "Allow after timer is completed:",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            CupertinoSwitch(
              value: _allowAfterTimeOut,
              onChanged: (value) => setState(
                () => _allowAfterTimeOut = value,
              ),
            ),
            const Spacer(
              flex: 3,
            ),
          ],
        ),
        const Spacer(),
        Text(
          "Detection Time-out Duration(In Seconds): ${_timeOutDuration == 100 ? "No Limit" : _timeOutDuration}",
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        Slider(
          min: 0,
          max: 100,
          value: _timeOutDuration.toDouble(),
          onChanged: (value) => setState(
            () => _timeOutDuration = value.toInt(),
          ),
        ),
        Expanded(
          flex: 14,
          child: ListView.builder(
            physics: const ClampingScrollPhysics(),
            itemCount: LivelynessCheckStep.values.length,
            itemBuilder: (context, index) => ExpansionTile(
              title: Text(
                _getTitle(
                  LivelynessCheckStep.values[index],
                ),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              children: [
                ListTile(
                  title: Text(
                    _getSubTitle(
                      LivelynessCheckStep.values[index],
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  trailing: CupertinoSwitch(
                    value: _isSelected(
                      LivelynessCheckStep.values[index],
                    ),
                    onChanged: (value) => _onStepValChanged(
                      LivelynessCheckStep.values[index],
                      value,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
