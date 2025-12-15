// lib/model/employee.dart

class Employee {
  final int empId;
  final String empName;
  final int? branchId;
  final String? empPosition;

  Employee({
    required this.empId,
    required this.empName,
    this.branchId,
    this.empPosition,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      empId: json['empId'] ?? 0,
      empName: json['empName'] ?? '',
      branchId: json['branchId'],
      empPosition: json['empPosition'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'empId': empId,
      'empName': empName,
      'branchId': branchId,
      'empPosition': empPosition,
    };
  }
}