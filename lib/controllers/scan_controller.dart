// lib/controllers/scan_controller.dart
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
}
