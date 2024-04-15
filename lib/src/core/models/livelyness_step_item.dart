
import 'package:demo_face_livelyness/index.dart';

class LivelynessStepItem {
  //enum
  final LivelynessCheckStep step;
  final String title;
  final double? thresholdToCheck;
  final bool isCompleted;

  LivelynessStepItem({
    required this.step,
    required this.title,
    this.thresholdToCheck,
    required this.isCompleted,
  });

  LivelynessStepItem copyWith({
    LivelynessCheckStep? step,
    String? title,
    double? thresholdToCheck,
    bool? isCompleted,
  }) {
    return LivelynessStepItem(
      step: step ?? this.step,
      title: title ?? this.title,
      thresholdToCheck: thresholdToCheck ?? this.thresholdToCheck,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'step': step.index});
    result.addAll({'title': title});
    if (thresholdToCheck != null) {
      result.addAll({'thresholdToCheck': thresholdToCheck});
    }
    result.addAll({'isCompleted': isCompleted});

    return result;
  }

  factory LivelynessStepItem.fromMap(Map<String, dynamic> map) {
    return LivelynessStepItem(
      step: LivelynessCheckStep.values[map['step'] ?? 0],
      title: map['title'] ?? '',
      thresholdToCheck: map['thresholdToCheck']?.toDouble(),
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory LivelynessStepItem.fromJson(String source) =>
      LivelynessStepItem.fromMap(json.decode(source));

  @override
  String toString() {
    return 'M7LivelynessStepItem(step: $step, title: $title, thresholdToCheck: $thresholdToCheck, isCompleted: $isCompleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LivelynessStepItem &&
        other.step == step &&
        other.title == title &&
        other.thresholdToCheck == thresholdToCheck &&
        other.isCompleted == isCompleted;
  }

  @override
  int get hashCode {
    return step.hashCode ^
        title.hashCode ^
        thresholdToCheck.hashCode ^
        isCompleted.hashCode;
  }
}
