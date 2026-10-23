import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../data/database/favorites_database.dart';
import '../models/favorite_audio.dart';

class FavoritesService {
  static const int maxFavoritesLimit = 20;

  final FavoritesDatabase _database;

  FavoritesService({FavoritesDatabase? database})
      : _database = database ?? FavoritesDatabase();

  /// Guarda el audio invertido en almacenamiento permanente y en SQLite
  /// Nombrando el archivo como: sonido-rever-fecha (ej: sonido-rever-2026-10-22_20-00-15)
  /// Mantiene únicamente las últimas 20 grabaciones para evitar saturar el almacenamiento.
  Future<FavoriteAudio> saveFavorite({
    required String tempReversedPath,
    required Duration duration,
  }) async {
    final DateTime now = DateTime.now();

    final String year = now.year.toString();
    final String month = now.month.toString().padLeft(2, '0');
    final String day = now.day.toString().padLeft(2, '0');
    final String hour = now.hour.toString().padLeft(2, '0');
    final String minute = now.minute.toString().padLeft(2, '0');
    final String second = now.second.toString().padLeft(2, '0');

    final String baseName =
        'sonido-rever-$year-$month-${day}_$hour-$minute-$second';

    // Directorio persistente de la app
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final Directory favoritesDir = Directory(p.join(appDocDir.path, 'favorites'));
    if (!await favoritesDir.exists()) {
      await favoritesDir.create(recursive: true);
    }

    final String targetFilePath = p.join(favoritesDir.path, '$baseName.wav');

    // Copiar el archivo temporal al directorio persistente
    final File sourceFile = File(tempReversedPath);
    if (!await sourceFile.exists()) {
      throw FileSystemException(
        'El archivo temporal de audio invertido no existe',
        tempReversedPath,
      );
    }

    await sourceFile.copy(targetFilePath);

    final FavoriteAudio newFavorite = FavoriteAudio(
      name: baseName,
      filePath: targetFilePath,
      createdAt: now,
      durationMs: duration.inMilliseconds,
    );

    final int insertedId = await _database.insertFavorite(newFavorite);
    debugPrint(
      '[FavoritesService] Sonido guardado en favoritos con id $insertedId: $baseName',
    );

    // Poda automática: conservar únicamente las últimas 20 grabaciones
    await pruneOldFavorites(maxKeep: maxFavoritesLimit);

    return newFavorite.copyWith(id: insertedId);
  }

  /// Mantiene únicamente las últimas [maxKeep] grabaciones (por defecto 20).
  /// Elimina de SQLite y del almacenamiento físico las grabaciones antiguas que superen el límite.
  Future<void> pruneOldFavorites({int maxKeep = maxFavoritesLimit}) async {
    try {
      final List<FavoriteAudio> all = await _database.getAllFavorites();
      if (all.length > maxKeep) {
        final List<FavoriteAudio> toRemove = all.sublist(maxKeep);
        for (final fav in toRemove) {
          debugPrint(
            '[FavoritesService] Límite de $maxKeep grabaciones alcanzado: eliminando "${fav.name}"',
          );
          await deleteFavorite(fav);
        }
      }
    } catch (e) {
      debugPrint('[FavoritesService] Error podando grabaciones antiguas: $e');
    }
  }

  /// Obtiene la lista completa de sonidos favoritos guardados
  Future<List<FavoriteAudio>> getFavorites() async {
    return await _database.getAllFavorites();
  }

  /// Elimina un sonido favorito individual de SQLite y del almacenamiento físico
  Future<bool> deleteFavorite(FavoriteAudio favorite) async {
    try {
      if (favorite.id != null) {
        await _database.deleteFavorite(favorite.id!);
      }

      final File file = File(favorite.filePath);
      if (await file.exists()) {
        await file.delete();
      }
      return true;
    } catch (e) {
      debugPrint('[FavoritesService] Error al eliminar favorito: $e');
      return false;
    }
  }

  /// Elimina todos los sonidos favoritos de SQLite y del almacenamiento físico
  Future<bool> deleteAllFavorites() async {
    try {
      final List<FavoriteAudio> all = await _database.getAllFavorites();
      for (final fav in all) {
        try {
          final File file = File(fav.filePath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          debugPrint(
            '[FavoritesService] No se pudo borrar archivo físico ${fav.filePath}: $e',
          );
        }
      }

      await _database.deleteAllFavorites();
      return true;
    } catch (e) {
      debugPrint('[FavoritesService] Error al eliminar todos los favoritos: $e');
      return false;
    }
  }

  /// Verifica si un archivo o nombre ya está registrado en favoritos
  Future<bool> isSaved({String? name, String? filePath}) async {
    return await _database.isFavoriteSaved(name: name, filePath: filePath);
  }
}
