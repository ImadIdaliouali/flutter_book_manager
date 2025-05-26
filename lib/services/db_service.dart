import 'dart:async';
import 'dart:developer' as developer;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/book.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'books.db');

    return await openDatabase(
      path,
      version: 2, // Increased version for migration
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
      onOpen: _onDatabaseOpen,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        coverUrl TEXT,
        openLibraryKey TEXT,
        UNIQUE(title, author)
      )
    ''');
  }

  // Handle database upgrades/migrations
  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      // Check if coverUrl column exists, if not add it
      try {
        await db.execute('ALTER TABLE favorites ADD COLUMN coverUrl TEXT');
      } catch (e) {
        // Column might already exist, check the table structure
        await _verifyTableStructure(db);
      }
    }
  }

  // Verify and fix table structure
  Future<void> _verifyTableStructure(Database db) async {
    try {
      final result = await db.rawQuery("PRAGMA table_info(favorites)");

      // Check if all required columns exist
      final columnNames = result.map((row) => row['name'] as String).toSet();
      final requiredColumns = {
        'id',
        'title',
        'author',
        'coverUrl',
        'openLibraryKey',
      };
      final missingColumns = requiredColumns.difference(columnNames);

      if (missingColumns.isNotEmpty) {
        // Recreate table with correct structure
        await _recreateTable(db);
      }
    } catch (e) {
      developer.log(
        'Error verifying table structure: $e',
        name: 'DatabaseService',
      );
      await _recreateTable(db);
    }
  }

  // Recreate table with correct structure
  Future<void> _recreateTable(Database db) async {
    try {
      // Backup existing data
      final existingData = await db.query('favorites');

      // Drop and recreate table
      await db.execute('DROP TABLE IF EXISTS favorites');
      await db.execute('''
        CREATE TABLE favorites (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          author TEXT NOT NULL,
          coverUrl TEXT,
          openLibraryKey TEXT,
          UNIQUE(title, author)
        )
      ''');

      // Restore data with proper column mapping
      for (final row in existingData) {
        final book = {
          'title': row['title'],
          'author': row['author'],
          'coverUrl': row['coverUrl'], // This might be null for old records
          'openLibraryKey': row['openLibraryKey'],
        };
        await db.insert('favorites', book);
      }
    } catch (e) {
      developer.log('Error recreating table: $e', name: 'DatabaseService');
      rethrow;
    }
  }

  // Called when database is opened
  Future<void> _onDatabaseOpen(Database db) async {
    await _verifyTableStructure(db);
  }

  // Insert a book into favorites
  Future<int> insertItem(Book book) async {
    try {
      final db = await database;

      // Check if book already exists
      final existing = await db.query(
        'favorites',
        where: 'title = ? AND author = ?',
        whereArgs: [book.title, book.author],
      );

      if (existing.isNotEmpty) {
        return existing.first['id'] as int;
      }

      final bookMap = book.toMap();
      // Remove id from map for insertion (auto-increment)
      bookMap.remove('id');

      // Validate required fields
      if (bookMap['title'] == null || bookMap['author'] == null) {
        throw Exception('Title and author are required fields');
      }

      final result = await db.insert(
        'favorites',
        bookMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return result;
    } catch (e) {
      developer.log('Error inserting book: $e', name: 'DatabaseService');

      // If it's a schema error, try to fix it
      if (e.toString().contains('no column named')) {
        try {
          final db = await database;
          await _verifyTableStructure(db);
          // Retry the insertion after fixing the schema
          return await insertItem(book);
        } catch (fixError) {
          developer.log(
            'Failed to fix database schema: $fixError',
            name: 'DatabaseService',
          );
        }
      }

      rethrow;
    }
  }

  // Get all favorite books
  Future<List<Book>> getItems() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('favorites');

      List<Book> books = List.generate(maps.length, (i) {
        return Book.fromMap(maps[i]);
      });

      return books;
    } catch (e) {
      developer.log('Error fetching books: $e', name: 'DatabaseService');
      return [];
    }
  }

  // Delete a book from favorites by ID
  Future<int> deleteItem(String id) async {
    try {
      final db = await database;
      final result = await db.delete(
        'favorites',
        where: 'id = ?',
        whereArgs: [id],
      );
      return result;
    } catch (e) {
      developer.log('Error deleting book: $e', name: 'DatabaseService');
      return 0;
    }
  }

  // Delete a book from favorites by title and author
  Future<int> deleteItemByTitleAuthor(String title, String author) async {
    try {
      final db = await database;
      final result = await db.delete(
        'favorites',
        where: 'title = ? AND author = ?',
        whereArgs: [title, author],
      );
      return result;
    } catch (e) {
      developer.log('Error deleting book: $e', name: 'DatabaseService');
      return 0;
    }
  }

  // Check if a book is in favorites
  Future<bool> isBookInFavorites(String title, String author) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'favorites',
        where: 'title = ? AND author = ?',
        whereArgs: [title, author],
      );

      return maps.isNotEmpty;
    } catch (e) {
      developer.log(
        'Error checking if book is in favorites: $e',
        name: 'DatabaseService',
      );
      return false;
    }
  }

  // Get a specific book from favorites
  Future<Book?> getBookByTitleAuthor(String title, String author) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'favorites',
        where: 'title = ? AND author = ?',
        whereArgs: [title, author],
      );

      if (maps.isNotEmpty) {
        return Book.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      developer.log('Error getting book: $e', name: 'DatabaseService');
      return null;
    }
  }

  // Clear all favorites
  Future<void> clearAllFavorites() async {
    try {
      final db = await database;
      await db.delete('favorites');
    } catch (e) {
      developer.log('Error clearing favorites: $e', name: 'DatabaseService');
    }
  }

  // Close the database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
