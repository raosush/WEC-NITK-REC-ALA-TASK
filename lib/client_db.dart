import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

final contactsTable = 'contacts';
final emergencyTable = 'templates';

class ClientDBProvider {
  static final ClientDBProvider dbProvider = ClientDBProvider();

  Database _database;

  // Getter to return database.
  Future<Database> get database async {
    if (_database != null) return _database;
    _database = await createDatabase();
    return _database;
  }

  // Create database to store user inputs.
  createDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'client.db');
    var database = await openDatabase(path, version: 1, onCreate: initDB);
    return database;
  }

  void initDB(Database database, int version) async {
    // Create emergency contacts table to store contacts selected by user.
    await database.execute(
        'CREATE TABLE $contactsTable (id INTEGER PRIMARY KEY, name TEXT, initials TEXT, number TEXT, uid TEXT)');
    // Create templates table to store emergency template added by user.
    await database.execute(
        'CREATE TABLE $emergencyTable (id INTEGER PRIMARY KEY, info TEXT, uid TEXT)');
  }
}
