import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/sunset.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._();

  DatabaseService._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    final path = p.join(await getDatabasesPath(), 'sunset_diary.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE sunsets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            place TEXT NOT NULL,
            description TEXT NOT NULL,
            imagePath TEXT NOT NULL,
            date TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL
          )
        ''');
      },
    );

    return _database!;
  }

  Future<Directory> _imagesDirectory() async {
    final documents = await getApplicationDocumentsDirectory();

    final directory = Directory(p.join(documents.path, 'sunset_images'));

    await directory.create(recursive: true);
    return directory;
  }

  String _newFilename(String imagePath) {
    final extension = p.extension(imagePath);

    return '${DateTime.now().microsecondsSinceEpoch}$extension';
  }

  Future<int> saveSunset(Sunset sunset) async {
    String? savedPath;

    try {
      final directory = await _imagesDirectory();
      final filename = _newFilename(sunset.imagePath);

      savedPath = p.join(directory.path, filename);

      await File(sunset.imagePath).copy(savedPath);

      final savedSunset = Sunset(
        title: sunset.title,
        place: sunset.place,
        description: sunset.description,
        imagePath: p.join('sunset_images', filename),
        date: sunset.date,
        latitude: sunset.latitude,
        longitude: sunset.longitude,
      );

      final db = await database;

      return await db.insert('sunsets', savedSunset.toMap());
    } catch (e) {
      if (savedPath != null) {
        final file = File(savedPath);

        if (await file.exists()) {
          try {
            await file.delete();
          } catch (_) {}
        }
      }
      rethrow;
    }
  }

  Future<List<Sunset>> getSunsets() async {
    final db = await database;
    final directory = await _imagesDirectory();
    final maps = await db.query('sunsets', orderBy: 'date DESC, id DESC');

    final sunsets = <Sunset>[];

    for (final map in maps) {
      final sunset = Sunset.fromMap(map);
      final originalPath = sunset.imagePath;

      String displayPath = originalPath;

      if (originalPath.startsWith('sunset_images/')) {
        displayPath = p.join(directory.path, p.basename(originalPath));
      } else if (originalPath.contains('/sunset_images/')) {
        final filename = p.basename(originalPath);
        final currentPath = p.join(directory.path, filename);

        if (await File(currentPath).exists()) {
          displayPath = currentPath;

          await db.update(
            'sunsets',
            {'imagePath': p.join('sunset_images', filename)},
            where: 'id = ?',
            whereArgs: [sunset.id],
          );
        }
      }

      sunsets.add(
        Sunset(
          id: sunset.id,
          title: sunset.title,
          place: sunset.place,
          description: sunset.description,
          imagePath: displayPath,
          date: sunset.date,
          latitude: sunset.latitude,
          longitude: sunset.longitude,
        ),
      );
    }

    return sunsets;
  }

  Future<String> updateSunsetImage(int id, String imagePath) async {
    String? newPath;
    bool updated = false;

    try {
      final db = await database;

      final records = await db.query(
        'sunsets',
        columns: ['imagePath'],
        where: 'id = ?',
        whereArgs: [id],
      );

      if (records.isEmpty) {
        throw Exception('El recuerdo no existe.');
      }

      final directory = await _imagesDirectory();
      final filename = _newFilename(imagePath);

      newPath = p.join(directory.path, filename);

      await File(imagePath).copy(newPath);

      final relativePath = p.join('sunset_images', filename);

      final count = await db.update(
        'sunsets',
        {'imagePath': relativePath},
        where: 'id = ?',
        whereArgs: [id],
      );

      if (count != 1) {
        throw Exception('No se pudo actualizar la fotografía.');
      }

      updated = true;

      final oldPath = records.first['imagePath'] as String;
      final oldFile = File(p.join(directory.path, p.basename(oldPath)));

      if (oldPath.contains('sunset_images/') &&
          oldFile.path != newPath &&
          await oldFile.exists()) {
        try {
          await oldFile.delete();
        } catch (_) {}
      }

      return newPath;
    } catch (e) {
      if (!updated && newPath != null) {
        final file = File(newPath);

        if (await file.exists()) {
          try {
            await file.delete();
          } catch (_) {}
        }
      }
      rethrow;
    }
  }

  Future<void> deleteSunset(Sunset sunset) async {
    final db = await database;

    final deleted = await db.delete(
      'sunsets',
      where: 'id = ?',
      whereArgs: [sunset.id],
    );

    if (deleted != 1) {
      throw Exception('No se pudo eliminar el recuerdo.');
    }

    final directory = await _imagesDirectory();
    final image = File(p.join(directory.path, p.basename(sunset.imagePath)));

    if (sunset.imagePath.contains('sunset_images/') && await image.exists()) {
      try {
        await image.delete();
      } catch (_) {}
    }
  }
}
