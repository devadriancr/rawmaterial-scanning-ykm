// lib/controllers/scan_controller.dart
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/scan_model.dart';

class ScanController {
  late Database _database;

  // Initialize the database
  Future<void> initDatabase() async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'scans.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE scans (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code TEXT UNIQUE,
            status BOOLEAN DEFAULT 1,
            created_at TEXT,
            updated_at TEXT
          )
        ''');
      },
    );
  }

  // Insert a new scan
  Future<void> insertScan(Scan scan) async {
    await _database.insert('scans', scan.toMap());
  }

  // Check if a scan code already exists
  Future<bool> scanExists(String code) async {
    List<Map<String, dynamic>> result = await _database.query(
      'scans',
      where: 'code = ?',
      whereArgs: [code],
    );
    return result.isNotEmpty;
  }

  // Get the number of active scans (status = 1)
  Future<int> getActiveScansCount() async {
    List<Map<String, dynamic>> countList = await _database
        .rawQuery('SELECT COUNT(*) AS count FROM scans WHERE status = 1');
    return countList.first['count'] as int;
  }

  // Get all active scans (status = 1)
  Future<List<Scan>> getActiveScans() async {
    List<Map<String, dynamic>> scanMaps =
        await _database.query('scans', where: 'status = 1');
    return List.generate(scanMaps.length, (i) {
      return Scan.fromMap(scanMaps[i]);
    });
  }

  // Method to delete a scan by its ID
  Future<void> deleteScan(int id) async {
    await _database.delete('scans', where: 'id = ?', whereArgs: [id]);
  }

  // Method to send data to the API
  Future<void> uploadScannedData(String code, String updatedAt) async {
    final url = Uri.parse(
        'http://192.168.130.9:8086/index.php/api/receive-raw-material');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'code': code,
        'updated_at': updatedAt,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 400) {
      // Delete the record if the response is 200 or 400
      await deleteScanByCode(code); // Additional method to delete the scan
    } else if (response.statusCode == 500) {
      // Handle connection or server error
      Fluttertoast.showToast(
        msg: "Connection error or server error",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  // Additional method to delete a scan by code
  Future<void> deleteScanByCode(String code) async {
    final scans = await getActiveScans();
    for (var scan in scans) {
      if (scan.code == code) {
        await deleteScan(scan.id!);
      }
    }
  }
}
