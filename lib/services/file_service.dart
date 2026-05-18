import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart'; // ✅ Для debugPrint
import '../models/combat_params.dart';

class FileService {
  /// Сохранить параметры в JSON файл
  Future<bool> saveParams(CombatParams params) async {
    try {
      // ✅ ИСПРАВЛЕНО: FilePicker.saveFile вместо FilePicker.platform.saveFile
      final result = await FilePicker.saveFile(
        dialogTitle: 'Сохранить параметры моделирования',
        fileName: 'scenario.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      
      if (result != null) {
        final file = File(result);
        await file.writeAsString(jsonEncode(params.toJson()));
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Ошибка сохранения: $e');
      return false;
    }
  }

  /// Загрузить параметры из JSON файла
  Future<CombatParams?> loadParams() async {
    try {
      // ✅ ИСПРАВЛЕНО: FilePicker.pickFiles вместо FilePicker.platform.pickFiles
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final json = jsonDecode(content);
        return CombatParams.fromJson(json);
      }
      return null;
    } catch (e) {
      debugPrint('Ошибка загрузки: $e');
      return null;
    }
  }

  /// Экспорт результатов в CSV
  Future<bool> exportResultsCsv(String content, String fileName) async {
    try {
      final result = await FilePicker.saveFile(
        dialogTitle: 'Экспорт результатов',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      
      if (result != null) {
        final file = File(result);
        await file.writeAsString(content);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Ошибка экспорта: $e');
      return false;
    }
  }

  /// Получить директорию для сохранений
  Future<String> getSaveDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// Универсальный метод для показа диалога сохранения файла
  Future<String?> saveFileWithPicker({
    required String dialogTitle,
    required String fileName,
    required String extension,
  }) async {
    try {
      final result = await FilePicker.saveFile(
        dialogTitle: dialogTitle,
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: [extension],
      );
      return result;
    } catch (e) {
      debugPrint('Ошибка выбора файла: $e');
      return null;
    }
  }

  /// Универсальный метод для загрузки файла
  Future<String?> loadFileWithPicker({
    required String dialogTitle,
    required String extension,
  }) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [extension],
      );
      if (result != null && result.files.single.path != null) {
        return result.files.single.path;
      }
      return null;
    } catch (e) {
      debugPrint('Ошибка выбора файла: $e');
      return null;
    }
  }
}