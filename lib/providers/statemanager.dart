import 'package:flutter/foundation.dart';
import '../models/unit_type.dart';
import '../models/combat_params.dart';

class StateManager with ChangeNotifier {
  final List<UnitType> _sideA = [];
  final List<UnitType> _sideB = [];

  // Матрицы эффективности
  List<List<double>> _effectivenessAvsB = [];
  List<List<double>> _effectivenessBvsA = [];

  // === Глобальные параметры морали ===
  double _moralDebaffA = 0.01;
  double _moralDebaffB = 0.01;
  double _epsilonSuccess = 0.5;  // === НОВОЕ: влияние успехов противника на мораль ===

  // === Параметры влияния морали на боеспособность ===
  double _gammaAtt = 1.0;
  double _gammaExp = 1.0;
  double _epsilonExp = 0.05;

  // === НОВОЕ: Параметры БПЛА/FPV ===
  double _kappaUav = 0.5;      // Влияние превосходства в БПЛА на уязвимость
  double _lambdaTech = 0.01;   // Техдеградация разведывательных БПЛА
  double _lambdaUse = 0.15;    // Боевое расходование FPV-дронов

  // === Параметры масштабирования коэффициентов потерь ===
  double _dRef = 1000.0;
  double _pScale = 1.6;
  double _sMin = 0.0001;       // === НОВОЕ: границы масштабирования ===
  double _sMax = 1.0;          // === НОВОЕ ===

  // === Параметры интегрирования ===
  double _dt = 0.01;
  int _steps = 1000;
  double _tolerance = 1e-6;
  int _maxNewtonIter = 15000;

  // Геттеры для списков войск
  List<UnitType> get sideA => List.unmodifiable(_sideA);
  List<UnitType> get sideB => List.unmodifiable(_sideB);

  // Геттеры для матриц
  List<List<double>> get effectivenessAvsB => _effectivenessAvsB
      .map<List<double>>((row) => List<double>.from(row))
      .toList();
  List<List<double>> get effectivenessBvsA => _effectivenessBvsA
      .map<List<double>>((row) => List<double>.from(row))
      .toList();

  // === Геттеры для глобальных параметров морали ===
  double get moralDebaffA => _moralDebaffA;
  double get moralDebaffB => _moralDebaffB;
  double get epsilonSuccess => _epsilonSuccess;  // === НОВОЕ ===

  // === Геттеры для параметров влияния морали ===
  double get gammaAtt => _gammaAtt;
  double get gammaExp => _gammaExp;
  double get epsilonExp => _epsilonExp;

  // === НОВОЕ: Геттеры для параметров БПЛА ===
  double get kappaUav => _kappaUav;
  double get lambdaTech => _lambdaTech;
  double get lambdaUse => _lambdaUse;

  // === Геттеры для параметров масштабирования ===
  double get dRef => _dRef;
  double get pScale => _pScale;
  double get sMin => _sMin;  // === НОВОЕ ===
  double get sMax => _sMax;  // === НОВОЕ ===

  // === Геттеры для параметров интегрирования ===
  double get dt => _dt;
  int get steps => _steps;
  double get tolerance => _tolerance;
  int get maxNewtonIter => _maxNewtonIter;

  // Геттер для полного CombatParams
  CombatParams getCombatParams() {
    return CombatParams(
      sideA: List.from(_sideA),
      sideB: List.from(_sideB),
      effectivenessAvsB: effectivenessAvsB,
      effectivenessBvsA: effectivenessBvsA,
      // Мораль
      moralDebaffA: _moralDebaffA,
      moralDebaffB: _moralDebaffB,
      epsilonSuccess: _epsilonSuccess,  // === НОВОЕ ===
      // Влияние морали
      gammaAtt: _gammaAtt,
      gammaExp: _gammaExp,
      epsilonExp: _epsilonExp,
      // === НОВОЕ: Параметры БПЛА ===
      kappaUav: _kappaUav,
      lambdaTech: _lambdaTech,
      lambdaUse: _lambdaUse,
      // Масштабирование
      dRef: _dRef,
      pScale: _pScale,
      sMin: _sMin,  // === НОВОЕ ===
      sMax: _sMax,  // === НОВОЕ ===
      // Интегрирование
      dt: _dt,
      steps: _steps,
      tolerance: _tolerance,
      maxNewtonIter: _maxNewtonIter,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Методы для управления войсками
  // ─────────────────────────────────────────────────────────────

  void addUnit(bool isSideA, UnitType unit) {
    if (isSideA) {
      _sideA.add(unit);
    } else {
      _sideB.add(unit);
    }
    _resizeMatrices();
    notifyListeners();
  }

  void updateUnit(int side, int index, UnitType updated) {
    if (side == 0 && index < _sideA.length) {
      _sideA[index] = updated;
    } else if (side == 1 && index < _sideB.length) {
      _sideB[index] = updated;
    }
    notifyListeners();
  }

  void removeUnit(int side, int index) {
    if (side == 0 && index < _sideA.length) {
      _sideA.removeAt(index);
    } else if (side == 1 && index < _sideB.length) {
      _sideB.removeAt(index);
    }
    _resizeMatrices();
    notifyListeners();
  }

  void clearAll() {
    _sideA.clear();
    _sideB.clear();
    _effectivenessAvsB = [];
    _effectivenessBvsA = [];
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────
  // Методы для матриц эффективности
  // ─────────────────────────────────────────────────────────────

  void updateEffectivenessMatrices({
    required List<List<double>> avsB,
    required List<List<double>> bvsA,
  }) {
    _effectivenessAvsB =
        avsB.map<List<double>>((row) => List<double>.from(row)).toList();
    _effectivenessBvsA =
        bvsA.map<List<double>>((row) => List<double>.from(row)).toList();
    notifyListeners();
  }

  void updateAvsBCell(int row, int col, double value) {
    if (row >= 0 &&
        row < _effectivenessAvsB.length &&
        col >= 0 &&
        col < _effectivenessAvsB[row].length) {
      _effectivenessAvsB[row][col] = value;
      notifyListeners();
    }
  }

  void updateBvsACell(int row, int col, double value) {
    if (row >= 0 &&
        row < _effectivenessBvsA.length &&
        col >= 0 &&
        col < _effectivenessBvsA[row].length) {
      _effectivenessBvsA[row][col] = value;
      notifyListeners();
    }
  }

  void resetEffectivenessMatrices() {
    final m = _sideA.length;
    final n = _sideB.length;

    if (m == 0 || n == 0) {
      _effectivenessAvsB = [];
      _effectivenessBvsA = [];
    } else {
      _effectivenessAvsB = List.generate(m, (_) => List.filled(n, 1.0));
      _effectivenessBvsA = List.generate(n, (_) => List.filled(m, 1.0));
    }
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────
  // ✅ Методы для глобальных параметров
  // ─────────────────────────────────────────────────────────────

  /// Обновляет все глобальные параметры сразу
  void updateGlobalParams({
    // Мораль
    double? moralDebaffA,
    double? moralDebaffB,
    double? epsilonSuccess,  // === НОВОЕ ===
    // Влияние морали
    double? gammaAtt,
    double? gammaExp,
    double? epsilonExp,
    // === НОВОЕ: Параметры БПЛА ===
    double? kappaUav,
    double? lambdaTech,
    double? lambdaUse,
    // Масштабирование
    double? dRef,
    double? pScale,
    double? sMin,  // === НОВОЕ ===
    double? sMax,  // === НОВОЕ ===
    // Интегрирование
    double? dt,
    int? steps,
    double? tolerance,
    int? maxNewtonIter,
  }) {
    if (moralDebaffA != null) _moralDebaffA = moralDebaffA;
    if (moralDebaffB != null) _moralDebaffB = moralDebaffB;
    if (epsilonSuccess != null) _epsilonSuccess = epsilonSuccess;  // === НОВОЕ ===
    
    if (gammaAtt != null) _gammaAtt = gammaAtt;
    if (gammaExp != null) _gammaExp = gammaExp;
    if (epsilonExp != null) _epsilonExp = epsilonExp;
    
    // === НОВОЕ: Параметры БПЛА ===
    if (kappaUav != null) _kappaUav = kappaUav;
    if (lambdaTech != null) _lambdaTech = lambdaTech;
    if (lambdaUse != null) _lambdaUse = lambdaUse;
    
    // Масштабирование
    if (dRef != null) _dRef = dRef;
    if (pScale != null) _pScale = pScale;
    if (sMin != null) _sMin = sMin;  // === НОВОЕ ===
    if (sMax != null) _sMax = sMax;  // === НОВОЕ ===
    
    // Интегрирование
    if (dt != null) _dt = dt;
    if (steps != null) _steps = steps;
    if (tolerance != null) _tolerance = tolerance;
    if (maxNewtonIter != null) _maxNewtonIter = maxNewtonIter;
    
    notifyListeners();
  }

  /// Сбрасывает параметры к значениям по умолчанию
  void resetGlobalParams() {
    // Мораль
    _moralDebaffA = 0.01;
    _moralDebaffB = 0.01;
    _epsilonSuccess = 0.5;  // === НОВОЕ ===
    
    // Влияние морали
    _gammaAtt = 1.0;
    _gammaExp = 1.0;
    _epsilonExp = 0.05;
    
    // === НОВОЕ: Параметры БПЛА ===
    _kappaUav = 0.5;
    _lambdaTech = 0.01;
    _lambdaUse = 0.15;
    
    // Масштабирование
    _dRef = 1000.0;
    _pScale = 1.6;
    _sMin = 0.0001;  // === НОВОЕ ===
    _sMax = 1.0;     // === НОВОЕ ===
    
    // Интегрирование
    _dt = 0.01;
    _steps = 1000;
    _tolerance = 1e-6;
    _maxNewtonIter = 15000;
    
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────
  // Внутренние методы
  // ─────────────────────────────────────────────────────────────

  void _resizeMatrices({double fillValue = 1.0}) {
    final m = _sideA.length;
    final n = _sideB.length;

    if (m == 0 || n == 0) {
      _effectivenessAvsB = [];
      _effectivenessBvsA = [];
      return;
    }

    _effectivenessAvsB = List<List<double>>.generate(m, (i) {
      if (i < _effectivenessAvsB.length) {
        final oldRow = _effectivenessAvsB[i];
        return List<double>.filled(n, fillValue)
          ..setAll(0, oldRow.take(min(n, oldRow.length)));
      }
      return List<double>.filled(n, fillValue);
    });

    _effectivenessBvsA = List<List<double>>.generate(n, (i) {
      if (i < _effectivenessBvsA.length) {
        final oldRow = _effectivenessBvsA[i];
        return List<double>.filled(m, fillValue)
          ..setAll(0, oldRow.take(min(m, oldRow.length)));
      }
      return List<double>.filled(m, fillValue);
    });
  }

  int min(int a, int b) => a < b ? a : b;

  // Загружает параметры из сохранённого файла
  void loadFromParams(CombatParams params) {
    // Очищаем текущее состояние
    _sideA.clear();
    _sideB.clear();
    _sideA.addAll(params.sideA);
    _sideB.addAll(params.sideB);

    // Матрицы эффективности
    _effectivenessAvsB =
        params.effectivenessAvsB.map((row) => List<double>.from(row)).toList();
    _effectivenessBvsA =
        params.effectivenessBvsA.map((row) => List<double>.from(row)).toList();

    // Обновляем глобальные параметры
    updateGlobalParams(
      // Мораль
      moralDebaffA: params.moralDebaffA,
      moralDebaffB: params.moralDebaffB,
      epsilonSuccess: params.epsilonSuccess,  // === НОВОЕ ===
      // Влияние морали
      gammaAtt: params.gammaAtt,
      gammaExp: params.gammaExp,
      epsilonExp: params.epsilonExp,
      // === НОВОЕ: Параметры БПЛА ===
      kappaUav: params.kappaUav,
      lambdaTech: params.lambdaTech,
      lambdaUse: params.lambdaUse,
      // Масштабирование
      dRef: params.dRef,
      pScale: params.pScale,
      sMin: params.sMin,  // === НОВОЕ ===
      sMax: params.sMax,  // === НОВОЕ ===
      // Интегрирование
      dt: params.dt,
      steps: params.steps,
      tolerance: params.tolerance,
      maxNewtonIter: params.maxNewtonIter,
    );
  }

  // Навигация
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  void navigateTo(int index) {
    if (index >= 0 && index <= 4) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void navigateNext() => navigateTo(_currentIndex + 1);
  void navigatePrevious() => navigateTo(_currentIndex - 1);

  // Настройки интерфейса
  bool useVideoBackground = true;

  void toggleBackground(bool value) {
    useVideoBackground = value;
    notifyListeners();
  }
}