import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import '../models/combat_params.dart';

// ─────────────────────────────────────────────────────────────
// 🔗 Типы функций FFI (обновлено под новые параметры)
// ─────────────────────────────────────────────────────────────
typedef RunSimulationNative = Pointer<Void> Function(
  // === Side A (11 параметров) ===
  Int32, // countA
  Pointer<Pointer<Utf8>>, // namesA
  Pointer<Double>, // countsA
  Pointer<Double>, // powersA
  Pointer<Double>, // defensesA
  Pointer<Double>, // moralesA
  Pointer<Double>, // suppliesA
  Pointer<Double>, // moraleDecaysA
  Pointer<Double>, // supplyDecaysA
  Pointer<Double>, // cpSupplySensA (НОВОЕ)
  Pointer<Bool>, // isUavA (НОВОЕ)
  Pointer<Bool>, // isFpvA (НОВОЕ)

  // === Side B (11 параметров) ===
  Int32, // countB
  Pointer<Pointer<Utf8>>, // namesB
  Pointer<Double>, // countsB
  Pointer<Double>, // powersB
  Pointer<Double>, // defensesB
  Pointer<Double>, // moralesB
  Pointer<Double>, // suppliesB
  Pointer<Double>, // moraleDecaysB
  Pointer<Double>, // supplyDecaysB
  Pointer<Double>, // cpSupplySensB (НОВОЕ)
  Pointer<Bool>, // isUavB (НОВОЕ)
  Pointer<Bool>, // isFpvB (НОВОЕ)

  // === Матрицы эффективности ===
  Pointer<Double>, // effectivenessAvsB (m*n)
  Pointer<Double>, // effectivenessBvsA (n*m)

  // === Глобальные параметры (16 значений) ===
  Double, // moral_debaffA
  Double, // moral_debaffB
  Double, // epsilon_success (НОВОЕ)
  Double, // gamma_att
  Double, // gamma_exp
  Double, // epsilon_exp
  Double, // kappa_uav (НОВОЕ)
  Double, // lambda_tech (НОВОЕ)
  Double, // lambda_use (НОВОЕ)
  Double, // dt
  Int32, // steps
  Double, // tolerance
  Int32, // max_newton_iter
  Double, // d_ref
  Double, // p_scale
  Double, // s_min (НОВОЕ)
  Double, // s_max (НОВОЕ)
);

typedef RunSimulationDart = Pointer<Void> Function(
  int,
  Pointer<Pointer<Utf8>>,
  Pointer<Double>,
  Pointer<Double>,
  Pointer<Double>,
  Pointer<Double>,
  Pointer<Double>,
  Pointer<Double>,
  Pointer<Double>,
  Pointer<Double>,
  Pointer<Bool>,
  Pointer<Bool>,
  int,
  Pointer<Pointer<Utf8>>,
  Pointer<Double>,
  Pointer<Double>,
  Pointer<Double>,
  Pointer<Double>,
  Pointer<Double>,
  Pointer<Double>,
  Pointer<Double>,
  Pointer<Double>,
  Pointer<Bool>,
  Pointer<Bool>,
  Pointer<Double>,
  Pointer<Double>,
  double,
  double,
  double,
  double,
  double,
  double,
  double,
  double,
  double,
  double,
  int,
  double,
  int,
  double,
  double,
  double,
  double,
);

// ─────────────────────────────────────────────────────────────
// 🧹 Очистка и геттеры (без изменений)
// ─────────────────────────────────────────────────────────────
typedef ResultsDestroy = Void Function(Pointer<Void>);
typedef ResultsDestroyDart = void Function(Pointer<Void>);

typedef ResultsGetTimeCount = Int32 Function(Pointer<Void>);
typedef ResultsGetTimeCountDart = int Function(Pointer<Void>);

typedef ResultsGetTypeCount = Int32 Function(Pointer<Void>);
typedef ResultsGetTypeCountDart = int Function(Pointer<Void>);

typedef ResultsGetTime = Double Function(Pointer<Void>, Int32);
typedef ResultsGetTimeDart = double Function(Pointer<Void>, int);
typedef ResultsGetDouble1D = Double Function(Pointer<Void>, Int32);
typedef ResultsGetDouble1DDart = double Function(Pointer<Void>, int);

typedef ResultsGetDouble2D = Double Function(Pointer<Void>, Int32, Int32);
typedef ResultsGetDouble2DDart = double Function(Pointer<Void>, int, int);

typedef ResultsGetDoubleSimple = Double Function(Pointer<Void>);
typedef ResultsGetDoubleSimpleDart = double Function(Pointer<Void>);

typedef ResultsGetIntSimple = Int32 Function(Pointer<Void>);
typedef ResultsGetIntSimpleDart = int Function(Pointer<Void>);

typedef ResultsExportCsv = Bool Function(Pointer<Void>, Pointer<Utf8>,
    Pointer<Pointer<Utf8>>, Int32, Pointer<Pointer<Utf8>>, Int32);
typedef ResultsExportCsvDart = bool Function(Pointer<Void>, Pointer<Utf8>,
    Pointer<Pointer<Utf8>>, int, Pointer<Pointer<Utf8>>, int);

// ─────────────────────────────────────────────────────────────
// 🛠️ Сервис FFI
// ─────────────────────────────────────────────────────────────
class FfiService {
  late DynamicLibrary _lib;

  // Функции
  late RunSimulationDart _runSimulation;
  late ResultsDestroyDart _resultsDestroy;
  late ResultsGetTimeCountDart _getTimeCount;
  late ResultsGetTypeCountDart _getTypeCountA;
  late ResultsGetTypeCountDart _getTypeCountB;
  late ResultsGetTimeDart _getTime;
  late ResultsGetDouble2DDart _getACount;
  late ResultsGetDouble2DDart _getBCount;
  late ResultsGetDouble2DDart _getAMorale;
  late ResultsGetDouble2DDart _getBMorale;
  late ResultsGetDouble2DDart _getASupply;
  late ResultsGetDouble2DDart _getBSupply;
  late ResultsGetDouble2DDart _getAAttack;
  late ResultsGetDouble2DDart _getBAttack;
  late ResultsGetDouble2DDart _getAExposure;
  late ResultsGetDouble2DDart _getBExposure;

  // === НОВОЕ: Геттеры для активности БПЛА ===
  late ResultsGetDouble1DDart _getUavActivityA;
  late ResultsGetDouble1DDart _getUavActivityB;

  // Статистика
  late ResultsGetDoubleSimpleDart _getExecTime;
  late ResultsGetDoubleSimpleDart _getInitialA;
  late ResultsGetDoubleSimpleDart _getInitialB;
  late ResultsGetDoubleSimpleDart _getFinalA;
  late ResultsGetDoubleSimpleDart _getFinalB;
  late ResultsGetIntSimpleDart _getWinner;
  late ResultsGetIntSimpleDart _getTotalIter;
  late ResultsGetIntSimpleDart _getConvergenceFailures;
  late ResultsGetDoubleSimpleDart _getAvgNewtonIter;
  late ResultsGetIntSimpleDart _getMaxNewtonIter;
  late ResultsExportCsvDart _exportCsv;

  FfiService() {
    _loadLibrary();
  }

  void _loadLibrary() {
    if (Platform.isWindows) {
      _lib = DynamicLibrary.open('combat_core.dll');
    } else if (Platform.isLinux) {
      _lib = DynamicLibrary.open('libcombat_core.so');
    } else if (Platform.isMacOS) {
      _lib = DynamicLibrary.open('libcombat_core.dylib');
    } else {
      throw UnsupportedError('Platform not supported');
    }

    _runSimulation =
        _lib.lookupFunction<RunSimulationNative, RunSimulationDart>(
            'run_simulation');
    _resultsDestroy = _lib
        .lookupFunction<ResultsDestroy, ResultsDestroyDart>('results_destroy');
    _getTimeCount =
        _lib.lookupFunction<ResultsGetTimeCount, ResultsGetTimeCountDart>(
            'results_get_time_count');
    _getTypeCountA =
        _lib.lookupFunction<ResultsGetTypeCount, ResultsGetTypeCountDart>(
            'results_get_type_count_a');
    _getTypeCountB =
        _lib.lookupFunction<ResultsGetTypeCount, ResultsGetTypeCountDart>(
            'results_get_type_count_b');
    _getTime = _lib
        .lookupFunction<ResultsGetTime, ResultsGetTimeDart>('results_get_time');
    _getACount =
        _lib.lookupFunction<ResultsGetDouble2D, ResultsGetDouble2DDart>(
            'results_get_a_count');
    _getBCount =
        _lib.lookupFunction<ResultsGetDouble2D, ResultsGetDouble2DDart>(
            'results_get_b_count');
    _getAMorale =
        _lib.lookupFunction<ResultsGetDouble2D, ResultsGetDouble2DDart>(
            'results_get_a_morale');
    _getBMorale =
        _lib.lookupFunction<ResultsGetDouble2D, ResultsGetDouble2DDart>(
            'results_get_b_morale');
    _getASupply =
        _lib.lookupFunction<ResultsGetDouble2D, ResultsGetDouble2DDart>(
            'results_get_a_supply');
    _getBSupply =
        _lib.lookupFunction<ResultsGetDouble2D, ResultsGetDouble2DDart>(
            'results_get_b_supply');
    _getAAttack =
        _lib.lookupFunction<ResultsGetDouble2D, ResultsGetDouble2DDart>(
            'results_get_a_attack');
    _getBAttack =
        _lib.lookupFunction<ResultsGetDouble2D, ResultsGetDouble2DDart>(
            'results_get_b_attack');
    _getAExposure =
        _lib.lookupFunction<ResultsGetDouble2D, ResultsGetDouble2DDart>(
            'results_get_a_exposure');
    _getBExposure =
        _lib.lookupFunction<ResultsGetDouble2D, ResultsGetDouble2DDart>(
            'results_get_b_exposure');

    // === НОВОЕ: Активность БПЛА ===
    _getUavActivityA =
        _lib.lookupFunction<ResultsGetDouble1D, ResultsGetDouble1DDart>(
            'results_get_uav_activity_a');
    _getUavActivityB =
        _lib.lookupFunction<ResultsGetDouble1D, ResultsGetDouble1DDart>(
            'results_get_uav_activity_b');

    // Статистика
    _getExecTime =
        _lib.lookupFunction<ResultsGetDoubleSimple, ResultsGetDoubleSimpleDart>(
            'results_get_execution_time_ms');
    _getInitialA =
        _lib.lookupFunction<ResultsGetDoubleSimple, ResultsGetDoubleSimpleDart>(
            'results_get_initial_force_a');
    _getInitialB =
        _lib.lookupFunction<ResultsGetDoubleSimple, ResultsGetDoubleSimpleDart>(
            'results_get_initial_force_b');
    _getFinalA =
        _lib.lookupFunction<ResultsGetDoubleSimple, ResultsGetDoubleSimpleDart>(
            'results_get_final_force_a');
    _getFinalB =
        _lib.lookupFunction<ResultsGetDoubleSimple, ResultsGetDoubleSimpleDart>(
            'results_get_final_force_b');
    _getWinner =
        _lib.lookupFunction<ResultsGetIntSimple, ResultsGetIntSimpleDart>(
            'results_get_winner');
    _getTotalIter =
        _lib.lookupFunction<ResultsGetIntSimple, ResultsGetIntSimpleDart>(
            'results_get_total_iterations');
    _getConvergenceFailures =
        _lib.lookupFunction<ResultsGetIntSimple, ResultsGetIntSimpleDart>(
            'results_get_convergence_failures');
    _getAvgNewtonIter =
        _lib.lookupFunction<ResultsGetDoubleSimple, ResultsGetDoubleSimpleDart>(
            'results_get_avg_newton_iterations');
    _getMaxNewtonIter =
        _lib.lookupFunction<ResultsGetIntSimple, ResultsGetIntSimpleDart>(
            'results_get_max_newton_iterations');
    _exportCsv = _lib.lookupFunction<ResultsExportCsv, ResultsExportCsvDart>(
        'results_export_to_csv');
  }

  // ─────────────────────────────────────────────────────────────
  // 🚀 ЕДИНСТВЕННЫЙ публичный метод для запуска
  // ─────────────────────────────────────────────────────────────
  Pointer<Void> runSimulation(CombatParams params) {
    final m = params.sideA.length;
    final n = params.sideB.length;

    // Хелперы для аллокации
    Pointer<Double> allocDoubleList(List<double> list) {
      final ptr = calloc<Double>(list.length);
      for (var i = 0; i < list.length; i++) {
        ptr[i] = list[i];
      }
      return ptr;
    }

    Pointer<Bool> allocBoolList(List<bool> list) {
      final ptr = calloc<Bool>(list.length);
      for (var i = 0; i < list.length; i++) {
        ptr[i] = list[i] ? true : false;
      }
      return ptr;
    }

    Pointer<Pointer<Utf8>> allocStringList(List<String> list) {
      final ptr = calloc<Pointer<Utf8>>(list.length);
      for (var i = 0; i < list.length; i++) {
        ptr[i] = list[i].toNativeUtf8();
      }
      return ptr;
    }

    void freeStringList(Pointer<Pointer<Utf8>> ptr, int length) {
      for (var i = 0; i < length; i++) {
        calloc.free(ptr[i]);
      }
      calloc.free(ptr);
    }

    // === Подготавливаем Side A ===
    final namesAPtr = allocStringList(params.sideA.map((u) => u.name).toList());
    final countsAPtr =
        allocDoubleList(params.sideA.map((u) => u.count).toList());
    final powersAPtr =
        allocDoubleList(params.sideA.map((u) => u.combatPower).toList());
    final defensesAPtr =
        allocDoubleList(params.sideA.map((u) => u.defense).toList());
    final moralesAPtr =
        allocDoubleList(params.sideA.map((u) => u.morale).toList());
    final suppliesAPtr =
        allocDoubleList(params.sideA.map((u) => u.supply).toList());
    final mDecaysAPtr =
        allocDoubleList(params.sideA.map((u) => u.moraleDecay).toList());
    final sDecaysAPtr =
        allocDoubleList(params.sideA.map((u) => u.supplyDecay).toList());

    // === НОВОЕ: Индивидуальная чувствительность и теги ===
    final cpSensAPtr = allocDoubleList(
        params.sideA.map((u) => u.cpSupplySensitivity).toList());
    final isUavAPtr = allocBoolList(params.sideA.map((u) => u.isUav).toList());
    final isFpvAPtr = allocBoolList(params.sideA.map((u) => u.isFpv).toList());

    // === Подготавливаем Side B ===
    final namesBPtr = allocStringList(params.sideB.map((u) => u.name).toList());
    final countsBPtr =
        allocDoubleList(params.sideB.map((u) => u.count).toList());
    final powersBPtr =
        allocDoubleList(params.sideB.map((u) => u.combatPower).toList());
    final defensesBPtr =
        allocDoubleList(params.sideB.map((u) => u.defense).toList());
    final moralesBPtr =
        allocDoubleList(params.sideB.map((u) => u.morale).toList());
    final suppliesBPtr =
        allocDoubleList(params.sideB.map((u) => u.supply).toList());
    final mDecaysBPtr =
        allocDoubleList(params.sideB.map((u) => u.moraleDecay).toList());
    final sDecaysBPtr =
        allocDoubleList(params.sideB.map((u) => u.supplyDecay).toList());

    // === НОВОЕ: Индивидуальная чувствительность и теги ===
    final cpSensBPtr = allocDoubleList(
        params.sideB.map((u) => u.cpSupplySensitivity).toList());
    final isUavBPtr = allocBoolList(params.sideB.map((u) => u.isUav).toList());
    final isFpvBPtr = allocBoolList(params.sideB.map((u) => u.isFpv).toList());

    // === Матрицы (плоские, row-major) ===
    final effAvsBFlat = calloc<Double>(m * n);
    final effBvsAFlat = calloc<Double>(n * m);
    for (var i = 0; i < m; i++) {
      for (var j = 0; j < n; j++) {
        effAvsBFlat[i * n + j] = params.effectivenessAvsB[i][j];
        effBvsAFlat[j * m + i] = params.effectivenessBvsA[j][i];
      }
    }

    // === Вызов нативной функции (16 глобальных параметров) ===
    final resultPtr = _runSimulation(
      // Side A (11 параметров)
      m, namesAPtr, countsAPtr, powersAPtr, defensesAPtr,
      moralesAPtr, suppliesAPtr, mDecaysAPtr, sDecaysAPtr,
      cpSensAPtr, isUavAPtr, isFpvAPtr,
      // Side B (11 параметров)
      n, namesBPtr, countsBPtr, powersBPtr, defensesBPtr,
      moralesBPtr, suppliesBPtr, mDecaysBPtr, sDecaysBPtr,
      cpSensBPtr, isUavBPtr, isFpvBPtr,
      // Matrices
      effAvsBFlat, effBvsAFlat,
      // Globals (16 параметров)
      params.moralDebaffA,
      params.moralDebaffB,
      params.epsilonSuccess, // НОВОЕ
      params.gammaAtt,
      params.gammaExp,
      params.epsilonExp,
      params.kappaUav, // НОВОЕ
      params.lambdaTech, // НОВОЕ
      params.lambdaUse, // НОВОЕ
      params.dt,
      params.steps,
      params.tolerance,
      params.maxNewtonIter,
      params.dRef,
      params.pScale,
      params.sMin, // НОВОЕ
      params.sMax, // НОВОЕ
    );

    // === Очистка памяти (ВАЖНО!) ===
    freeStringList(namesAPtr, m);
    calloc.free(countsAPtr);
    calloc.free(powersAPtr);
    calloc.free(defensesAPtr);
    calloc.free(moralesAPtr);
    calloc.free(suppliesAPtr);
    calloc.free(mDecaysAPtr);
    calloc.free(sDecaysAPtr);
    calloc.free(cpSensAPtr);
    calloc.free(isUavAPtr);
    calloc.free(isFpvAPtr);

    freeStringList(namesBPtr, n);
    calloc.free(countsBPtr);
    calloc.free(powersBPtr);
    calloc.free(defensesBPtr);
    calloc.free(moralesBPtr);
    calloc.free(suppliesBPtr);
    calloc.free(mDecaysBPtr);
    calloc.free(sDecaysBPtr);
    calloc.free(cpSensBPtr);
    calloc.free(isUavBPtr);
    calloc.free(isFpvBPtr);

    calloc.free(effAvsBFlat);
    calloc.free(effBvsAFlat);

    return resultPtr;
  }

  void destroyResults(Pointer<Void> ptr) => _resultsDestroy(ptr);

  // ─────────────────────────────────────────────────────────────
  // 📊 Геттеры результатов
  // ─────────────────────────────────────────────────────────────
  int getTimeCount(Pointer<Void> results) => _getTimeCount(results);
  int getTypeCountA(Pointer<Void> results) => _getTypeCountA(results);
  int getTypeCountB(Pointer<Void> results) => _getTypeCountB(results);
  double getTime(Pointer<Void> results, int index) => _getTime(results, index);

  double getACount(Pointer<Void> results, int typeIdx, int timeIdx) =>
      _getACount(results, typeIdx, timeIdx);
  double getBCount(Pointer<Void> results, int typeIdx, int timeIdx) =>
      _getBCount(results, typeIdx, timeIdx);
  double getAMorale(Pointer<Void> results, int typeIdx, int timeIdx) =>
      _getAMorale(results, typeIdx, timeIdx);
  double getBMorale(Pointer<Void> results, int typeIdx, int timeIdx) =>
      _getBMorale(results, typeIdx, timeIdx);
  double getASupply(Pointer<Void> results, int typeIdx, int timeIdx) =>
      _getASupply(results, typeIdx, timeIdx);
  double getBSupply(Pointer<Void> results, int typeIdx, int timeIdx) =>
      _getBSupply(results, typeIdx, timeIdx);
  double getAAttack(Pointer<Void> results, int typeIdx, int timeIdx) =>
      _getAAttack(results, typeIdx, timeIdx);
  double getBAttack(Pointer<Void> results, int typeIdx, int timeIdx) =>
      _getBAttack(results, typeIdx, timeIdx);
  double getAExposure(Pointer<Void> results, int typeIdx, int timeIdx) =>
      _getAExposure(results, typeIdx, timeIdx);
  double getBExposure(Pointer<Void> results, int typeIdx, int timeIdx) =>
      _getBExposure(results, typeIdx, timeIdx);

  // === НОВОЕ: Геттеры для активности БПЛА ===
  double getUavActivityA(Pointer<Void> results, int timeIdx) =>
      _getUavActivityA(results, timeIdx);
  double getUavActivityB(Pointer<Void> results, int timeIdx) =>
      _getUavActivityB(results, timeIdx);

  // Статистика
  double getExecutionTime(Pointer<Void> results) => _getExecTime(results);
  double getInitialForceA(Pointer<Void> results) => _getInitialA(results);
  double getInitialForceB(Pointer<Void> results) => _getInitialB(results);
  double getFinalForceA(Pointer<Void> results) => _getFinalA(results);
  double getFinalForceB(Pointer<Void> results) => _getFinalB(results);
  int getWinner(Pointer<Void> results) => _getWinner(results);
  int getTotalIterations(Pointer<Void> results) => _getTotalIter(results);
  int getConvergenceFailures(Pointer<Void> results) =>
      _getConvergenceFailures(results);
  double getAvgNewtonIterations(Pointer<Void> results) =>
      _getAvgNewtonIter(results);
  int getMaxNewtonIterations(Pointer<Void> results) =>
      _getMaxNewtonIter(results);

  // ─────────────────────────────────────────────────────────────
  // 💾 Экспорт
  // ─────────────────────────────────────────────────────────────
  bool exportToCsv(Pointer<Void> results, String filepath, List<String> namesA,
      List<String> namesB) {
    final pathPtr = filepath.toNativeUtf8();
    final namesAPtr = calloc<Pointer<Utf8>>(namesA.length);
    final namesBPtr = calloc<Pointer<Utf8>>(namesB.length);

    for (var i = 0; i < namesA.length; i++) {
      namesAPtr[i] = namesA[i].toNativeUtf8();
    }
    for (var i = 0; i < namesB.length; i++) {
      namesBPtr[i] = namesB[i].toNativeUtf8();
    }

    final ok = _exportCsv(
        results, pathPtr, namesAPtr, namesA.length, namesBPtr, namesB.length);

    for (var i = 0; i < namesA.length; i++) {
      calloc.free(namesAPtr[i]);
    }
    for (var i = 0; i < namesB.length; i++) {
      calloc.free(namesBPtr[i]);
    }
    calloc.free(namesAPtr);
    calloc.free(namesBPtr);
    calloc.free(pathPtr);

    return ok;
  }
}
