// ignore_for_file: depend_on_referenced_packages

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:rever/features/favorites/data/database/favorites_database.dart';
import 'package:rever/features/favorites/domain/models/favorite_audio.dart';
import 'package:rever/features/favorites/domain/services/favorites_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final Directory tempDir;
  MockPathProviderPlatform(this.tempDir);

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return tempDir.path;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Database db;
  late FavoritesDatabase favoritesDatabase;
  late FavoritesService favoritesService;
  late Directory tempAppDocDir;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute('''
      CREATE TABLE ${FavoritesDatabase.tableName} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        file_path TEXT NOT NULL,
        created_at TEXT NOT NULL,
        duration_ms INTEGER NOT NULL
      )
    ''');
    favoritesDatabase = FavoritesDatabase.withDatabase(db);
    favoritesService = FavoritesService(database: favoritesDatabase);

    tempAppDocDir = await Directory.systemTemp.createTemp('fav_test_doc_');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempAppDocDir);
  });

  tearDown(() async {
    await db.close();
    if (await tempAppDocDir.exists()) {
      await tempAppDocDir.delete(recursive: true);
    }
  });

  group('FavoriteAudio Model', () {
    test('toMap and fromMap work properly', () {
      final now = DateTime.now();
      final audio = FavoriteAudio(
        id: 1,
        name: 'sonido-rever-2026-10-22_20-00-00',
        filePath: '/path/to/test.wav',
        createdAt: now,
        durationMs: 3500,
      );

      final map = audio.toMap();
      final reconstructed = FavoriteAudio.fromMap(map);

      expect(reconstructed.id, 1);
      expect(reconstructed.name, 'sonido-rever-2026-10-22_20-00-00');
      expect(reconstructed.filePath, '/path/to/test.wav');
      expect(reconstructed.durationMs, 3500);
      expect(reconstructed.formattedDuration, '00:03');
    });
  });

  group('Favorites Database and Service with SQLite', () {
    test('saveFavorite copies physical audio file and persists in SQLite', () async {
      // Crear archivo temporal simulado de audio en reversa
      final tempReversedFile = File('${tempAppDocDir.path}/temp_rever.wav');
      await tempReversedFile.writeAsString('RIFF dummy wav audio content');

      final saved = await favoritesService.saveFavorite(
        tempReversedPath: tempReversedFile.path,
        duration: const Duration(seconds: 4),
      );

      expect(saved.id, isNotNull);
      expect(saved.name.startsWith('sonido-rever-'), isTrue);
      expect(saved.durationMs, 4000);
      expect(await File(saved.filePath).exists(), isTrue);

      final list = await favoritesService.getFavorites();
      expect(list.length, 1);
      expect(list.first.name, saved.name);
      expect(list.first.filePath, saved.filePath);
    });

    test('deleteFavorite removes from database and deletes physical file', () async {
      final tempReversedFile = File('${tempAppDocDir.path}/temp_rever.wav');
      await tempReversedFile.writeAsString('RIFF dummy wav audio content');

      final saved = await favoritesService.saveFavorite(
        tempReversedPath: tempReversedFile.path,
        duration: const Duration(seconds: 2),
      );

      expect(await File(saved.filePath).exists(), isTrue);

      final deleteResult = await favoritesService.deleteFavorite(saved);
      expect(deleteResult, isTrue);

      final list = await favoritesService.getFavorites();
      expect(list.isEmpty, isTrue);
      expect(await File(saved.filePath).exists(), isFalse);
    });

    test('deleteAllFavorites removes all records and physical files', () async {
      final f1 = File('${tempAppDocDir.path}/temp1.wav');
      await f1.writeAsString('wav1');
      final f2 = File('${tempAppDocDir.path}/temp2.wav');
      await f2.writeAsString('wav2');

      final s1 = await favoritesService.saveFavorite(
        tempReversedPath: f1.path,
        duration: const Duration(seconds: 2),
      );
      final s2 = await favoritesService.saveFavorite(
        tempReversedPath: f2.path,
        duration: const Duration(seconds: 3),
      );

      expect((await favoritesService.getFavorites()).length, 2);
      expect(await File(s1.filePath).exists(), isTrue);
      expect(await File(s2.filePath).exists(), isTrue);

      final deleteAllRes = await favoritesService.deleteAllFavorites();
      expect(deleteAllRes, isTrue);

      expect((await favoritesService.getFavorites()).isEmpty, isTrue);
      expect(await File(s1.filePath).exists(), isFalse);
      expect(await File(s2.filePath).exists(), isFalse);
    });

    test(
      'pruneOldFavorites limits recordings to max 20 and deletes older ones',
      () async {
        final List<FavoriteAudio> created = [];
        for (int i = 0; i < 22; i++) {
          final f = File('${tempAppDocDir.path}/temp_prune_$i.wav');
          await f.writeAsString('audio content $i');
          final fav = await favoritesService.saveFavorite(
            tempReversedPath: f.path,
            duration: Duration(seconds: i + 1),
          );
          created.add(fav);
          await Future.delayed(const Duration(milliseconds: 15));
        }

        final list = await favoritesService.getFavorites();
        expect(list.length, 20);

        // La primera grabación creada debe haber sido eliminada automáticamente de disco
        expect(await File(created.first.filePath).exists(), isFalse);
        // La última grabación creada debe existir en disco
        expect(await File(created.last.filePath).exists(), isTrue);
      },
    );
  });
}

