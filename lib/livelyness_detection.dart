import 'package:flutter/material.dart';

import 'index.dart';

class LivelynessDetection {
  LivelynessDetection._privateConstructor();

  static final LivelynessDetection instance =
      LivelynessDetection._privateConstructor();

  final List<LivelynessDetectionThreshold> _thresholds = [];
  Color? _contourDetectionColor;
  late EdgeInsets _safeAreaPadding;

  List<LivelynessDetectionThreshold> get thresholdConfig {
    return _thresholds;
  }

  EdgeInsets get safeAreaPadding {
    return _safeAreaPadding;
  }

  Color? get contourDetectionColor {
    return _contourDetectionColor;
  }

  //* MARK: - Public Methods
  //? =========================================================

  /// A single line functoin to detect weather the face is live or not.
  /// Parameters: -
  /// * context: - Positional Parameter that will accept a `BuildContext` using which it will redirect the a new screen.
  /// * config: - Accepts a `M7DetectionConfig` object which will hold all the setup config of the package.
  Future<String?> detectLivelyness(
    BuildContext context, {
    required LivelynessDetectionConfig config,
  }) async {
    _safeAreaPadding = MediaQuery.of(context).padding;
    final String? capturedFacePath = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LivelynessDetectionScreen(
          config: config,
        ),
      ),
    );
    return capturedFacePath;
  }

  /// Configures the shreshold values of which will be used while verfying
  /// Parameters: -
  /// * thresholds: - List of [LivelynessDetectionThreshold] objects.
  /// * contourColor - Color of the points that are plotted on the face while detecting.
  void configure({
    required List<LivelynessDetectionThreshold> thresholds,
    Color contourColor = const Color(0xffab48e0),
  }) {
    assert(
      thresholds.isNotEmpty,
      "Threshold configuration cannot be empty",
    );
    _thresholds.clear();
    _thresholds.addAll(thresholds);
    _contourDetectionColor = contourColor;
  }
}
