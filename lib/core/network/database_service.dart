import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/menu_item.dart';
import '../../models/venue.dart'; // Прибрано зайвий пробіл у назві файлу, якщо такий був

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mapmenu.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // 1. Таблиця користувачів
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        isVerified INTEGER NOT NULL
      )
    ''');

    // Додаємо тестового користувача для входу
    await db.insert('users', {
      'email': 'test@mapmenu.com',
      'password': 'password123',
      'isVerified': 1,
    });

    // 2. Таблиця закладів з геопозицією та статусом модерації
    await db.execute('''
      CREATE TABLE venues (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        status TEXT NOT NULL
      )
    ''');

    // 3. Таблиця позицій меню (зв'язана з закладом через venueId)
    await db.execute('''
      CREATE TABLE menu_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        venueId INTEGER NOT NULL,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        price REAL NOT NULL,
        source TEXT NOT NULL,
        FOREIGN KEY (venueId) REFERENCES venues (id) ON DELETE CASCADE
      )
    ''');
  }

  // --- МЕТОДИ АВТОРИЗАЦІЇ ---

  Future<bool> loginUser(String email, String password) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    return result.isNotEmpty;
  }

  Future<int> registerUser(String email, String password) async {
    final db = await instance.database;
    return await db.insert('users', {
      'email': email,
      'password': password,
      'isVerified': 0,
    });
  }

  // --- МЕТОДИ ДЛЯ ЗАКЛАДІВ (VENUES) ---

  // Додавання нового закладу (у статус pending)
  Future<int> insertVenue(Venue venue) async {
    final db = await instance.database;
    return await db.insert('venues', venue.toMap());
  }

  // Отримання лише схвалених закладів для відображення на карті
  Future<List<Venue>> getApprovedVenues() async {
    final db = await instance.database;
    final result = await db.query(
      'venues',
      where: 'status = ?',
      whereArgs: ['approved'],
    );
    return result.map((json) => Venue.fromMap(json)).toList();
  }

  // --- МЕТОДИ ДЛЯ МЕНЮ (MENU ITEMS) ---

  // Додавання позиції
  Future<int> insertMenuItem(MenuItem item) async {
    final db = await instance.database;
    return await db.insert('menu_items', item.toMap());
  }

  // Отримання меню для конкретного закладу
  Future<List<MenuItem>> getMenuItemsForVenue(int venueId) async {
    final db = await instance.database;
    final result = await db.query(
      'menu_items',
      where: 'venueId = ?',
      whereArgs: [venueId],
    );
    return result.map((json) => MenuItem.fromMap(json)).toList();
  }

  // Отримання всіх позицій меню з бази
  Future<List<MenuItem>> getAllMenuItems() async {
    final db = await instance.database;
    final result = await db.query('menu_items');
    return result.map((json) => MenuItem.fromMap(json)).toList();
  }
}