// lib/services/simulation_service.dart
import 'dart:ffi';
import 'ffi_service.dart';
import 'file_service.dart';
import '../models/combat_params.dart';
import '../models/simulation_results.dart';

/// Высокоуровневый сервис для работы с симуляцией
/// Скрывает всю работу с FFI и указателями
class SimulationService {
  final FfiService _ffi;
  final FileService _files;

  SimulationService({FfiService? ffi, FileService? files})
      : _ffi = ffi ?? FfiService(),
        _files = files ?? FileService();

  /// 🚀 Запускает симуляцию и возвращает готовые Dart-данные
  ///
  /// ⚠️ Должен вызываться через compute() в отдельном изоляте!
  SimulationResults run(CombatParams params) {
    final resultsPtr = _ffi.runSimulation(params);
    try {
      return _readResults(resultsPtr);
    } finally {
      _ffi.destroyResults(resultsPtr);
    }
  }

  /// 🚀 Запускает симуляцию и возвращает результаты + указатель (для экспорта)
  ///
  /// ⚠️ Вызывающий код обязан вызвать _ffi.destroyResults() когда результаты больше не нужны!
  SimulationResultsWithPtr runWithPointer(CombatParams params) {
    final resultsPtr = _ffi.runSimulation(params);
    final results = _readResults(resultsPtr);
    return SimulationResultsWithPtr(results, resultsPtr);
  }

  /// Внутренний метод: читает данные из нативного указателя
  SimulationResults _readResults(Pointer<Void> ptr) {
    final timeCount = _ffi.getTimeCount(ptr);
    final typeCountA = _ffi.getTypeCountA(ptr);
    final typeCountB = _ffi.getTypeCountB(ptr);

    final time = List<double>.generate(timeCount, (i) => _ffi.getTime(ptr, i));

    final aCounts = List<List<double>>.generate(
        typeCountA,
        (i) =>
            List<double>.generate(timeCount, (t) => _ffi.getACount(ptr, i, t)));
    final bCounts = List<List<double>>.generate(
        typeCountB,
        (i) =>
            List<double>.generate(timeCount, (t) => _ffi.getBCount(ptr, i, t)));

    final aMorale = List<List<double>>.generate(
        typeCountA,
        (i) => List<double>.generate(
            timeCount, (t) => _ffi.getAMorale(ptr, i, t)));
    final bMorale = List<List<double>>.generate(
        typeCountB,
        (i) => List<double>.generate(
            timeCount, (t) => _ffi.getBMorale(ptr, i, t)));

    final aSupply = List<List<double>>.generate(
        typeCountA,
        (i) => List<double>.generate(
            timeCount, (t) => _ffi.getASupply(ptr, i, t)));
    final bSupply = List<List<double>>.generate(
        typeCountB,
        (i) => List<double>.generate(
            timeCount, (t) => _ffi.getBSupply(ptr, i, t)));

    // === НОВОЕ: Чтение активности БПЛА ===
    final uavActivityA = List<double>.generate(
        timeCount, (t) => _ffi.getUavActivityA(ptr, t));
    final uavActivityB = List<double>.generate(
        timeCount, (t) => _ffi.getUavActivityB(ptr, t));

    return SimulationResults(
      time: time,
      aCounts: aCounts,
      bCounts: bCounts,
      aMorale: aMorale,
      bMorale: bMorale,
      aSupply: aSupply,
      bSupply: bSupply,
      // === НОВОЕ: Активность БПЛА ===
      uavActivityA: uavActivityA,
      uavActivityB: uavActivityB,
      // Статистика
      executionTimeMs: _ffi.getExecutionTime(ptr),
      totalIterations: _ffi.getTotalIterations(ptr),
      convergenceFailures: _ffi.getConvergenceFailures(ptr),
      initialForceA: _ffi.getInitialForceA(ptr),
      initialForceB: _ffi.getInitialForceB(ptr),
      finalForceA: _ffi.getFinalForceA(ptr),
      finalForceB: _ffi.getFinalForceB(ptr),
      winner: _ffi.getWinner(ptr),
      avgNewtonIterations: _ffi.getAvgNewtonIterations(ptr),
      maxNewtonIterations: _ffi.getMaxNewtonIterations(ptr),
    );
  }

  /// 📤 Экспорт результатов в CSV через нативный код DLL
  Future<bool> exportResultsToCsv(
    Pointer<Void> resultsPtr,
    List<String> namesA,
    List<String> namesB,
  ) async {
    final result = await _files.saveFileWithPicker(
      dialogTitle: 'Экспорт результатов',
      fileName: 'results_${DateTime.now().millisecondsSinceEpoch}.csv',
      extension: 'csv',
    );

    if (result == null) return false;

    return _ffi.exportToCsv(resultsPtr, result, namesA, namesB);
  }

  /// 💾 Сохранение параметров в JSON (через FileService)
  Future<bool> saveParams(CombatParams params) {
    return _files.saveParams(params);
  }

  /// 📂 Загрузка параметров из JSON
  Future<CombatParams?> loadParams() {
    return _files.loadParams();
  }
}

/// Вспомогательный класс для хранения результатов + нативного указателя
class SimulationResultsWithPtr {
  final SimulationResults results;
  final Pointer<Void> nativePtr;

  SimulationResultsWithPtr(this.results, this.nativePtr);
}