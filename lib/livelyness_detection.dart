

import 'dart:io';

import 'package:flutter/material.dart';

import 'index.dart';
import 'livelyness_detection_screen.dart';

class LivelynessDetection {
  //* MARK: - Converting Package to Singleton
  //? =========================================================
  LivelynessDetection._privateConstructor();

  static final LivelynessDetection instance =
  LivelynessDetection._privateConstructor();

  //* MARK: - Private Variables
  //? =========================================================
  final List<LivelynessDetectionThreshold> _thresholds = [];
  Color? _contourLineColor;
  Color? _contourDotColor;
  double? _contourDotRadius;
  double? _contourLineWidth;
  bool _displayLines = true;
  bool _displayDots = true;
  List<double>? _dashValues;

  late EdgeInsets _safeAreaPadding;

  //* MARK: - Public Variables
  //? =========================================================
  List<LivelynessDetectionThreshold> get thresholdConfig {
    return _thresholds;
  }

  EdgeInsets get safeAreaPadding {
    return _safeAreaPadding;
  }

  Color? get contourLineColor {
    return _contourLineColor;
  }

  Color? get contourDotColor {
    return _contourDotColor;
  }

  double? get contourDotRadius {
    return _contourDotRadius;
  }

  double? get contourLineWidth {
    return _contourLineWidth;
  }

  bool get displayLines {
    return _displayLines;
  }

  bool get displayDots {
    return _displayDots;
  }

  bool get displayDash {
    return _dashValues != null && _dashValues!.length == 2;
  }

  double get dashLength {
    return _dashValues?[0] ?? 5;
  }

  double get dashGap {
    return _dashValues?[1] ?? 5;
  }

  //* MARK: - Public Methods
  //? =========================================================

  /// A single line functoin to detect weather the face is live or not.
  /// Parameters: -
  /// * context: - Positional Parameter that will accept a `BuildContext` using which it will redirect the a new screen.
  /// * config: - Accepts a `DetectionConfig` object which will hold all the setup config of the package.
  Future<dynamic> detectLivelyness(
      BuildContext context, {
        required LivelynessDetectionConfig config,
      }) async {
    _safeAreaPadding = MediaQuery.of(context).padding;
    final dynamic capturedFacePath = await Navigator.of(context).push(
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
  /// * thresholds: - List of [DetectionThreshold] objects.
  /// * contourColor - Color of the points that are plotted on the face while detecting.
  void configure({
    required List<LivelynessDetectionThreshold> thresholds,
    Color lineColor = const Color(0xffab48e0),
    Color dotColor = const Color(0xffab48e0),
    double lineWidth = 1.6,
    double dotSize = 2.0,
    bool displayLines = true,
    bool displayDots = true,
    List<double>? dashValues,
  }) {
    assert(
    thresholds.isNotEmpty,
    "Threshold configuration cannot be empty",
    );
    assert(
    _dashValues == null || _dashValues!.length == 2,
    "Dash values must be of length 2",
    );
    _thresholds.clear();
    _thresholds.addAll(thresholds);
    _contourLineColor = lineColor;
    _contourDotColor = dotColor;
    _contourDotRadius = dotSize;
    _contourLineWidth = lineWidth;
    _displayLines = displayLines;
    _displayDots = displayDots;
    _dashValues = dashValues;
  }
}
