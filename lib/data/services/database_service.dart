import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/scan_result_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), 'cicipscan_database.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE scan_results(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        score TEXT,
        imagePath TEXT,
        timestamp TEXT
      )
    ''');
  }

  Future<int> insertScanResult(ScanResultModel result) async {
    final db = await database;
    return await db.insert(
      'scan_results',
      result.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ScanResultModel>> getScanResults() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'scan_results',
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) {
      return ScanResultModel.fromMap(maps[i]);
    });
  }

  Future<int> deleteScanResult(int id) async {
    final db = await database;
    return await db.delete('scan_results', where: 'id = ?', whereArgs: [id]);
  }
}
