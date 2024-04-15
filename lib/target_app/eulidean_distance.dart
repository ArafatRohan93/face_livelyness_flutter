import 'dart:math';

/// Adds the power of the difference between each point
/// then computes the sqrt of the result 📐
double euclideanDistance(List storedFaceData, List predictedFaceData) {
  double sum = 0.0;
  for (int i = 0; i < storedFaceData.length; i++) {
    sum += pow((storedFaceData[i] - predictedFaceData[i]), 2);
  }
  return sqrt(sum);
}
