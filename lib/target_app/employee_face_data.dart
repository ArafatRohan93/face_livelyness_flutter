class EmployeeFaceData {
  String name;
  int employeeId;
  String image;
  double result = 0;

  EmployeeFaceData(
      {required this.name, required this.employeeId, required this.image});

  factory EmployeeFaceData.fromJson(Map<String, dynamic> json) {
    return EmployeeFaceData(
        name: json['name'],
        employeeId: json['employee_id'],
        image: json['image']);
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'employee_id': employeeId, 'image': image};
  }

  /// format double list to string
  static String formatDoubleListToString(List<dynamic> listOfData) {
    String data = '';
    for (var element in listOfData) {
      data += (' $element');
    }
    return data;
  }

  /// format string data to double points
  static List<double> formatStringToDouble(String data) {
    List<double> doubleDataPoints = [];
    var listOfString = data.split(' ');
    for (var element in listOfString) {
      if (element.isNotEmpty) {
        doubleDataPoints.add(double.tryParse(element) ?? 0);
      }
    }
    return doubleDataPoints;
  }
}
