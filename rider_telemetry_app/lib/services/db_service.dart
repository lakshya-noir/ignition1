import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/telemetry_model.dart';

class DbService {
  Database? _db;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'telemetry.db');
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE telemetry(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT,
            accelX REAL,
            accelY REAL,
            accelZ REAL,
            accelMag REAL,
            speed REAL,
            latitude REAL,
            longitude REAL
          );
        ''');
      },
    );
  }

  /// Insert one telemetry record
  Future<void> insertTelemetry(Telemetry t) async {
    await _db?.insert(
      'telemetry',
      t.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Count how many records are stored
  Future<int> count() async {
    final res = await _db?.rawQuery('SELECT COUNT(*) AS c FROM telemetry');
    return (res?.first['c'] as int?) ?? 0;
  }

  /// Optional: Retrieve the latest telemetry entry
  Future<Telemetry?> getLastEntry() async {
    final res = await _db?.query(
      'telemetry',
      orderBy: 'id DESC',
      limit: 1,
    );
    if (res != null && res.isNotEmpty) {
      final data = res.first;
      return Telemetry(
        timestamp: DateTime.parse(data['timestamp'] as String),
        accelX: data['accelX'] as double,
        accelY: data['accelY'] as double,
        accelZ: data['accelZ'] as double,
        accelMag: data['accelMag'] as double,
        speed: data['speed'] as double,
        latitude: data['latitude'] as double,
        longitude: data['longitude'] as double,
      );
    }
    return null;
  }
}
