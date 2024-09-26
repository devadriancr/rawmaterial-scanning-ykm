// lib/models/scan_model.dart
class Scan {
  final int? id;
  final String code;
  final bool status;
  final String createdAt;
  final String updatedAt;

  Scan({
    this.id,
    required this.code,
    this.status = true,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert a Scan to Map (for SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'status': status ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // Convert a Map to Scan
  factory Scan.fromMap(Map<String, dynamic> map) {
    return Scan(
      id: map['id'],
      code: map['code'],
      status: map['status'] == 1,
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }
}
