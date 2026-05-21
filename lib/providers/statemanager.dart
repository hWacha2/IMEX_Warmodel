// lib/providers/statemanager.dart
import 'package:flutter/foundation.dart';
import '../models/unit_type.dart';
import '../models/combat_params.dart';

class StateManager with ChangeNotifier {
  // ─────────────────────────────────────────────────────────────
  // Списки войск
  // ─────────────────────────────────────────────────────────────
  final List<UnitType> _sideA = [];
  final List<UnitType> _sideB = [];

  // ─────────────────────────────────────────────────────────────
  // === Универсальные теги типов войск ===
  // ─────────────────────────────────────────────────────────────
  final List<String> _tags = ['пехота', 'бпла', 'фпв']; // Дефолтный тег

  // ─────────────────────────────────────────────────────────────
  // === Матрицы эффективности ===
  // ─────────────────────────────────────────────────────────────

  // Маленькая матрица по тегам (ввод пользователя, сериализуется)
  Map<String, Map<String, double>> _tagEffectivenessAvsB = {};
  Map<String, Map<String, double>> _tagEffectivenessBvsA = {};

  // Полные матрицы по юнитам (независимые, редактируемые вручную, также сериализуются)
  List<List<double>> _effectivenessAvsB = [];
  List<List<double>> _effectivenessBvsA = [];

  // ─────────────────────────────────────────────────────────────
  // === Глобальные параметры модели ===
  // ─────────────────────────────────────────────────────────────

  // Параметры морали
  double _moralDebaffA = 0.01;
  double _moralDebaffB = 0.01;
  double _epsilonSuccess = 0.5;

  // Параметры влияния морали на боеспособность
  double _gammaAtt = 1.0;
  double _gammaExp = 1.0;
  double _epsilonExp = 0.05;

  // Параметры БПЛА/FPV
  double _kappaUav = 0.5;
  double _lambdaTech = 0.01;
  double _lambdaUse = 0.15;

  // Параметры масштабирования коэффициентов потерь
  double _dRef = 1000.0;
  double _pScale = 1.6;
  double _sMin = 0.0001;
  double _sMax = 1.0;

  // Параметры интегрирования
  double _dt = 0.01;
  int _steps = 1000;
  double _tolerance = 1e-6;
  int _maxNewtonIter = 15000;

  // ─────────────────────────────────────────────────────────────
  // Геттеры для списков войск
  // ─────────────────────────────────────────────────────────────
  List<UnitType> get sideA => List.unmodifiable(_sideA);
  List<UnitType> get sideB => List.unmodifiable(_sideB);

  // ─────────────────────────────────────────────────────────────
  // Геттеры для тегов
  // ─────────────────────────────────────────────────────────────
  List<String> get tags => List.unmodifiable(_tags);

  // ─────────────────────────────────────────────────────────────
  // Геттеры для матриц по тегам (для UI)
  // ─────────────────────────────────────────────────────────────
  Map<String, Map<String, double>> get tagEffectivenessAvsB =>
      Map.fromEntries(_tagEffectivenessAvsB.entries.map(
        (e) => MapEntry(e.key, Map.from(e.value)),
      ));

  Map<String, Map<String, double>> get tagEffectivenessBvsA =>
      Map.fromEntries(_tagEffectivenessBvsA.entries.map(
        (e) => MapEntry(e.key, Map.from(e.value)),
      ));

  // ─────────────────────────────────────────────────────────────
  // Геттеры для полных матриц (для C++ и ручного редактирования)
  // ─────────────────────────────────────────────────────────────
  List<List<double>> get effectivenessAvsB =>
      _effectivenessAvsB.map((row) => List<double>.from(row)).toList();

  List<List<double>> get effectivenessBvsA =>
      _effectivenessBvsA.map((row) => List<double>.from(row)).toList();

  // ─────────────────────────────────────────────────────────────
  // Геттеры для глобальных параметров
  // ─────────────────────────────────────────────────────────────
  double get moralDebaffA => _moralDebaffA;
  double get moralDebaffB => _moralDebaffB;
  double get epsilonSuccess => _epsilonSuccess;

  double get gammaAtt => _gammaAtt;
  double get gammaExp => _gammaExp;
  double get epsilonExp => _epsilonExp;

  double get kappaUav => _kappaUav;
  double get lambdaTech => _lambdaTech;
  double get lambdaUse => _lambdaUse;

  double get dRef => _dRef;
  double get pScale => _pScale;
  double get sMin => _sMin;
  double get sMax => _sMax;

  double get dt => _dt;
  int get steps => _steps;
  double get tolerance => _tolerance;
  int get maxNewtonIter => _maxNewtonIter;

  // ─────────────────────────────────────────────────────────────
  // === Методы управления тегами ===
  // ─────────────────────────────────────────────────────────────

  /// Добавляет новый тег и инициализирует ячейки матрицы
  void addTag(String tag) {
    final trimmed = tag.trim().toLowerCase();
    if (trimmed.isEmpty || _tags.contains(trimmed)) return;

    _tags.add(trimmed);
    _initializeTagMatrixCells(trimmed);
    notifyListeners();
  }

  /// Редактирует тег (переименование)
  void editTag(String oldTag, String newTag) {
    final trimmed = newTag.trim().toLowerCase();
    if (trimmed.isEmpty || trimmed == oldTag) return;

    // Переименовываем в списке тегов
    final index = _tags.indexOf(oldTag);
    if (index != -1) {
      _tags[index] = trimmed;
    }

    // Переименовываем в матрицах по тегам
    _renameTagInMatrix(_tagEffectivenessAvsB, oldTag, trimmed);
    _renameTagInMatrix(_tagEffectivenessBvsA, oldTag, trimmed);

    // Обновляем теги у юнитов
    for (final unit in _sideA) {
      if (unit.tag == oldTag) unit.tag = trimmed;
    }
    for (final unit in _sideB) {
      if (unit.tag == oldTag) unit.tag = trimmed;
    }

    // Пересчитываем полные матрицы
    _rebuildFullMatrices();
    notifyListeners();
  }

  /// Вспомогательный метод для переименования тега в матрице
  void _renameTagInMatrix(
    Map<String, Map<String, double>> matrix,
    String oldTag,
    String newTag,
  ) {
    if (matrix.containsKey(oldTag)) {
      final values = matrix.remove(oldTag)!;
      matrix[newTag] = values;
    }
    for (final entry in matrix.entries) {
      if (entry.value.containsKey(oldTag)) {
        final val = entry.value.remove(oldTag);
        if (val != null) entry.value[newTag] = val;
      }
    }
  }

  /// Удаляет тег и все юниты с этим тегом
  void removeTag(String tag) {
    if (!_tags.contains(tag)) return;

    _tags.remove(tag);

    // Удаляем из матриц по тегам
    _tagEffectivenessAvsB.remove(tag);
    _tagEffectivenessBvsA.remove(tag);
    for (final entry in _tagEffectivenessAvsB.entries) {
      entry.value.remove(tag);
    }
    for (final entry in _tagEffectivenessBvsA.entries) {
      entry.value.remove(tag);
    }

    // Удаляем юниты с этим тегом
    _sideA.removeWhere((u) => u.tag == tag);
    _sideB.removeWhere((u) => u.tag == tag);

    // Пересчитываем полные матрицы
    _rebuildFullMatrices();
    notifyListeners();
  }

  /// Инициализирует ячейки матрицы для нового тега
  void _initializeTagMatrixCells(String newTag) {
    // Инициализируем AvsB
    _tagEffectivenessAvsB.putIfAbsent(newTag, () => {});
    for (final existingTag in _tags) {
      if (existingTag != newTag) {
        _tagEffectivenessAvsB[existingTag] ??= {};
        _tagEffectivenessAvsB[existingTag]![newTag] ??= 1.0;
        _tagEffectivenessAvsB[newTag]![existingTag] ??= 1.0;
      }
    }
    _tagEffectivenessAvsB[newTag]![newTag] ??= 1.0;

    // Инициализируем BvsA
    _tagEffectivenessBvsA.putIfAbsent(newTag, () => {});
    for (final existingTag in _tags) {
      if (existingTag != newTag) {
        _tagEffectivenessBvsA[existingTag] ??= {};
        _tagEffectivenessBvsA[existingTag]![newTag] ??= 1.0;
        _tagEffectivenessBvsA[newTag]![existingTag] ??= 1.0;
      }
    }
    _tagEffectivenessBvsA[newTag]![newTag] ??= 1.0;

    // Авто-настройка дефолтных значений для спец. тегов
    final lowerTag = newTag.toLowerCase();
    if (lowerTag == 'бпла' ) {
      // БПЛА: низкая эффективность против техники, высокая против пехоты
      _tagEffectivenessAvsB[newTag]?['танк'] = 0.1;
      _tagEffectivenessAvsB[newTag]?['пехота'] = 0.3;
    } else if (lowerTag == 'фпв' ) {
      // FPV: высокая эффективность против техники
      _tagEffectivenessAvsB[newTag]?['танк'] = 2.0;
      _tagEffectivenessAvsB[newTag]?['пехота'] = 1.5;
    }
  }

  /// Обновляет ячейку матрицы по тегам (A vs B)
  void updateTagAvsBCell(String attackerTag, String defenderTag, double value) {
    _tagEffectivenessAvsB.putIfAbsent(attackerTag, () => {});
    _tagEffectivenessAvsB[attackerTag]![defenderTag] = value;
    notifyListeners();
  }

  /// Обновляет ячейку матрицы по тегам (B vs A)
  void updateTagBvsACell(String attackerTag, String defenderTag, double value) {
    _tagEffectivenessBvsA.putIfAbsent(attackerTag, () => {});
    _tagEffectivenessBvsA[attackerTag]![defenderTag] = value;
    notifyListeners();
  }

  /// === ЯВНАЯ СИНХРОНИЗАЦИЯ: разворачивает матрицу по тегам в полную ===
  void syncEffectivenessFromTags() {
    _rebuildFullMatrices();
    notifyListeners();
  }

  /// Разворачивает матрицу по тегам в полную матрицу по юнитам
  void _rebuildFullMatrices() {
    final m = _sideA.length;
    final n = _sideB.length;

    if (m == 0 || n == 0) {
      _effectivenessAvsB = [];
      _effectivenessBvsA = [];
      return;
    }

    // A vs B: атакующие — sideA, защитники — sideB
    _effectivenessAvsB = List.generate(
      m,
      (i) => List.generate(
        n,
        (j) {
          final attTag = _sideA[i].tag.isEmpty ? 'пехота' : _sideA[i].tag;
          final defTag = _sideB[j].tag.isEmpty ? 'пехота' : _sideB[j].tag;
          return _tagEffectivenessAvsB[attTag]?[defTag] ?? 1.0;
        },
      ),
    );

    // B vs A: атакующие — sideB, защитники — sideA
    _effectivenessBvsA = List.generate(
      n,
      (i) => List.generate(
        m,
        (j) {
          final attTag = _sideB[i].tag.isEmpty ? 'пехота' : _sideB[i].tag;
          final defTag = _sideA[j].tag.isEmpty ? 'пехота' : _sideA[j].tag;
          return _tagEffectivenessBvsA[attTag]?[defTag] ?? 1.0;
        },
      ),
    );
  }

  /// Изменяет размер полных матриц, сохраняя ручные правки
  void _resizeEffectivenessMatrices({double fillValue = 1.0}) {
    final m = _sideA.length;
    final n = _sideB.length;

    if (m == 0 || n == 0) {
      _effectivenessAvsB = [];
      _effectivenessBvsA = [];
      return;
    }

    // Сохраняем старые значения
    final oldAvsB = List<List<double>>.from(
        _effectivenessAvsB.map((row) => List<double>.from(row)));
    final oldBvsA = List<List<double>>.from(
        _effectivenessBvsA.map((row) => List<double>.from(row)));

    // Создаём новые матрицы нужного размера
    _effectivenessAvsB = List.generate(m, (i) {
      if (i < oldAvsB.length) {
        final oldRow = oldAvsB[i];
        return List<double>.filled(n, fillValue)..setAll(0, oldRow.take(n));
      }
      return List<double>.filled(n, fillValue);
    });

    _effectivenessBvsA = List.generate(n, (i) {
      if (i < oldBvsA.length) {
        final oldRow = oldBvsA[i];
        return List<double>.filled(m, fillValue)..setAll(0, oldRow.take(m));
      }
      return List<double>.filled(m, fillValue);
    });
  }

  // ─────────────────────────────────────────────────────────────
  // Методы для управления войсками
  // ─────────────────────────────────────────────────────────────

  void addUnit(bool isSideA, UnitType unit) {
    // Если тега нет в списке, добавляем его
    if (!_tags.contains(unit.tag)) {
      addTag(unit.tag);
    }

    if (isSideA) {
      _sideA.add(unit);
    } else {
      _sideB.add(unit);
    }

    // Меняем размер матриц, сохраняя старые значения
    _resizeEffectivenessMatrices();

    notifyListeners();
  }

  void updateUnit(int side, int index, UnitType updated) {
    if (side == 0 && index < _sideA.length) {
      _sideA[index] = updated;
    } else if (side == 1 && index < _sideB.length) {
      _sideB[index] = updated;
    }

    // Пересчитываем полные матрицы при изменении тега
    _rebuildFullMatrices();

    notifyListeners();
  }

  void removeUnit(int side, int index) {
    if (side == 0 && index < _sideA.length) {
      _sideA.removeAt(index);
    } else if (side == 1 && index < _sideB.length) {
      _sideB.removeAt(index);
    }

    // Меняем размер матриц, сохраняя старые значения
    _resizeEffectivenessMatrices();

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
  // Методы для ручного редактирования полных матриц
  // ─────────────────────────────────────────────────────────────

  void updateEffectivenessMatrices({
    required List<List<double>> avsB,
    required List<List<double>> bvsA,
  }) {
    _effectivenessAvsB = avsB.map((row) => List<double>.from(row)).toList();
    _effectivenessBvsA = bvsA.map((row) => List<double>.from(row)).toList();
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
    _rebuildFullMatrices();
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────
  // Глобальные параметры
  // ─────────────────────────────────────────────────────────────

  void updateGlobalParams({
    // Мораль
    double? moralDebaffA,
    double? moralDebaffB,
    double? epsilonSuccess,
    // Влияние морали
    double? gammaAtt,
    double? gammaExp,
    double? epsilonExp,
    // Параметры БПЛА
    double? kappaUav,
    double? lambdaTech,
    double? lambdaUse,
    // Масштабирование
    double? dRef,
    double? pScale,
    double? sMin,
    double? sMax,
    // Интегрирование
    double? dt,
    int? steps,
    double? tolerance,
    int? maxNewtonIter,
  }) {
    if (moralDebaffA != null) _moralDebaffA = moralDebaffA;
    if (moralDebaffB != null) _moralDebaffB = moralDebaffB;
    if (epsilonSuccess != null) _epsilonSuccess = epsilonSuccess;

    if (gammaAtt != null) _gammaAtt = gammaAtt;
    if (gammaExp != null) _gammaExp = gammaExp;
    if (epsilonExp != null) _epsilonExp = epsilonExp;

    if (kappaUav != null) _kappaUav = kappaUav;
    if (lambdaTech != null) _lambdaTech = lambdaTech;
    if (lambdaUse != null) _lambdaUse = lambdaUse;

    if (dRef != null) _dRef = dRef;
    if (pScale != null) _pScale = pScale;
    if (sMin != null) _sMin = sMin;
    if (sMax != null) _sMax = sMax;

    if (dt != null) _dt = dt;
    if (steps != null) _steps = steps;
    if (tolerance != null) _tolerance = tolerance;
    if (maxNewtonIter != null) _maxNewtonIter = maxNewtonIter;

    notifyListeners();
  }

  void resetGlobalParams() {
    _moralDebaffA = 0.01;
    _moralDebaffB = 0.01;
    _epsilonSuccess = 0.5;
    _gammaAtt = 1.0;
    _gammaExp = 1.0;
    _epsilonExp = 0.05;
    _kappaUav = 0.5;
    _lambdaTech = 0.01;
    _lambdaUse = 0.15;
    _dRef = 1000.0;
    _pScale = 1.6;
    _sMin = 0.0001;
    _sMax = 1.0;
    _dt = 0.01;
    _steps = 1000;
    _tolerance = 1e-6;
    _maxNewtonIter = 15000;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────
  // Загрузка/сохранение параметров
  // ─────────────────────────────────────────────────────────────

  void loadFromParams(CombatParams params) {
    // Очищаем текущее состояние
    _sideA.clear();
    _sideB.clear();
    _sideA.addAll(params.sideA);
    _sideB.addAll(params.sideB);

    // 1) Системные теги
    final defaultTags = {'пехота', 'бпла', 'фпв'};

// 2) Теги из файла
    final loadedTags = <String>{};
    for (final unit in params.sideA) {
      loadedTags.add(unit.tag);
    }
    for (final unit in params.sideB) {
      loadedTags.add(unit.tag);
    }

// 3) Объединяем без повторов
    final merged = <String>{}
      ..addAll(defaultTags)
      ..addAll(loadedTags);

// 4) Перезаписываем _tags
    _tags
      ..clear()
      ..addAll(merged);

    // Загружаем матрицы по тегам (если есть)
    if (params.tagEffectivenessAvsB.isNotEmpty) {
      _tagEffectivenessAvsB = Map.from(params.tagEffectivenessAvsB);
    } else {
      // Восстанавливаем упрощённо: все теги → 1.0
      for (final tagA in _tags) {
        _tagEffectivenessAvsB[tagA] = {};
        for (final tagB in _tags) {
          _tagEffectivenessAvsB[tagA]![tagB] = 1.0;
        }
      }
    }
    if (params.tagEffectivenessBvsA.isNotEmpty) {
      _tagEffectivenessBvsA = Map.from(params.tagEffectivenessBvsA);
    } else {
      for (final tagB in _tags) {
        _tagEffectivenessBvsA[tagB] = {};
        for (final tagA in _tags) {
          _tagEffectivenessBvsA[tagB]![tagA] = 1.0;
        }
      }
    }

    // Загружаем полные матрицы (если есть) — они имеют приоритет
    if (params.effectivenessAvsB.isNotEmpty) {
      _effectivenessAvsB = params.effectivenessAvsB
          .map((row) => List<double>.from(row))
          .toList();
    }
    if (params.effectivenessBvsA.isNotEmpty) {
      _effectivenessBvsA = params.effectivenessBvsA
          .map((row) => List<double>.from(row))
          .toList();
    }

    // Если полные матрицы пусты — разворачиваем из тегов
    if (_effectivenessAvsB.isEmpty && _sideA.isNotEmpty && _sideB.isNotEmpty) {
      _rebuildFullMatrices();
    }

    // Обновляем глобальные параметры
    updateGlobalParams(
      moralDebaffA: params.moralDebaffA,
      moralDebaffB: params.moralDebaffB,
      epsilonSuccess: params.epsilonSuccess,
      gammaAtt: params.gammaAtt,
      gammaExp: params.gammaExp,
      epsilonExp: params.epsilonExp,
      kappaUav: params.kappaUav,
      lambdaTech: params.lambdaTech,
      lambdaUse: params.lambdaUse,
      dRef: params.dRef,
      pScale: params.pScale,
      sMin: params.sMin,
      sMax: params.sMax,
      dt: params.dt,
      steps: params.steps,
      tolerance: params.tolerance,
      maxNewtonIter: params.maxNewtonIter,
    );

    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────
  // Геттер для CombatParams (для передачи в C++ и сохранения)
  // ─────────────────────────────────────────────────────────────

  CombatParams getCombatParams() {
    // Если полные матрицы пусты — разворачиваем из тегов как фоллбэк
    if (_effectivenessAvsB.isEmpty && _sideA.isNotEmpty && _sideB.isNotEmpty) {
      _rebuildFullMatrices();
    }

    return CombatParams(
      sideA: List.from(_sideA),
      sideB: List.from(_sideB),
      // Передаём ОБЕ матрицы для сохранения
      tagEffectivenessAvsB: Map.from(_tagEffectivenessAvsB),
      tagEffectivenessBvsA: Map.from(_tagEffectivenessBvsA),
      effectivenessAvsB: effectivenessAvsB,
      effectivenessBvsA: effectivenessBvsA,
      // Глобальные параметры
      moralDebaffA: _moralDebaffA,
      moralDebaffB: _moralDebaffB,
      epsilonSuccess: _epsilonSuccess,
      gammaAtt: _gammaAtt,
      gammaExp: _gammaExp,
      epsilonExp: _epsilonExp,
      kappaUav: _kappaUav,
      lambdaTech: _lambdaTech,
      lambdaUse: _lambdaUse,
      dRef: _dRef,
      pScale: _pScale,
      sMin: _sMin,
      sMax: _sMax,
      dt: _dt,
      steps: _steps,
      tolerance: _tolerance,
      maxNewtonIter: _maxNewtonIter,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Навигация и настройки интерфейса
  // ─────────────────────────────────────────────────────────────

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

  bool useVideoBackground = true;

  void toggleBackground(bool value) {
    useVideoBackground = value;
    notifyListeners();
  }
}
