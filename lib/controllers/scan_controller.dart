import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/scan_model.dart';

class ScanController {
  late Database _database;

  // Inicializar la base de datos
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
            code TEXT,
            status BOOLEAN DEFAULT 1,
            created_at TEXT,
            updated_at TEXT
          )
        ''');
      },
    );
  }

  // Insertar un nuevo scan
  Future<void> insertScan(Scan scan) async {
    await _database.insert('scans', scan.toMap());
  }

  // Obtener el número de scans activos (status = 1)
  Future<int> getActiveScansCount() async {
    List<Map<String, dynamic>> countList = await _database
        .rawQuery('SELECT COUNT(*) AS count FROM scans WHERE status = 1');
    return countList.first['count'] as int;
  }

  // Obtener todos los scans activos (status = 1)
  Future<List<Scan>> getActiveScans() async {
    List<Map<String, dynamic>> scanMaps =
        await _database.query('scans', where: 'status = 1');
    return List.generate(scanMaps.length, (i) {
      return Scan.fromMap(scanMaps[i]);
    });
  }

  // Método para eliminar un scan por su ID
  Future<void> deleteScan(int id) async {
    await _database.delete('scans', where: 'id = ?', whereArgs: [id]);
  }

  // Método para enviar datos a la API
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
      // Eliminar el registro si la respuesta es 200 o 400
      await deleteScanByCode(code); // Método adicional para eliminar el scan
    } else if (response.statusCode == 500) {
      // Manejar error de conexión o del servidor
      Fluttertoast.showToast(
        msg: "Error de conexión o error del servidor",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  // Método adicional para eliminar un scan por código
  Future<void> deleteScanByCode(String code) async {
    final scans = await getActiveScans();
    for (var scan in scans) {
      if (scan.code == code) {
        await deleteScan(scan.id!);
      }
    }
  }
}
