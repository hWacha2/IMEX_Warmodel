// lib/models/combat_params.dart
import 'unit_type.dart';

class CombatParams {
  List<UnitType> sideA;
  List<UnitType> sideB;
  
  // === Матрицы эффективности ПО ТЕГАМ (вводятся пользователем, сериализуются) ===
  Map<String, Map<String, double>> tagEffectivenessAvsB;
  Map<String, Map<String, double>> tagEffectivenessBvsA;
  
  // === Полные матрицы ПО ЮНИТАМ (редактируемые вручную, ТАКЖЕ сериализуются) ===
  List<List<double>> effectivenessAvsB;
  List<List<double>> effectivenessBvsA;
  
  // Параметры морали
  double moralDebaffA;
  double moralDebaffB;
  double epsilonSuccess;
  
  // Параметры влияния морали на боеспособность
  double gammaAtt;
  double gammaExp;
  double epsilonExp;
  
  // === Параметры БПЛА/FPV ===
  double kappaUav;
  double lambdaTech;
  double lambdaUse;
  
  // Параметры масштабирования коэффициентов потерь
  double dRef;
  double pScale;
  double sMin;
  double sMax;
  
  // Параметры интегрирования
  double dt;
  int steps;
  double tolerance;
  int maxNewtonIter;

  CombatParams({
    this.sideA = const [],
    this.sideB = const [],
    // === Матрицы по тегам ===
    Map<String, Map<String, double>>? tagEffectivenessAvsB,
    Map<String, Map<String, double>>? tagEffectivenessBvsA,
    // === Полные матрицы по юнитам ===
    List<List<double>>? effectivenessAvsB,
    List<List<double>>? effectivenessBvsA,
    this.moralDebaffA = 0.01,
    this.moralDebaffB = 0.01,
    this.epsilonSuccess = 0.5,
    this.gammaAtt = 1.0,
    this.gammaExp = 1.0,
    this.epsilonExp = 0.05,
    this.kappaUav = 0.5,
    this.lambdaTech = 0.01,
    this.lambdaUse = 0.15,
    this.dRef = 1000.0,
    this.pScale = 1.6,
    this.sMin = 0.0001,
    this.sMax = 1.0,
    this.dt = 0.01,
    this.steps = 1000,
    this.tolerance = 1e-6,
    this.maxNewtonIter = 15000,
  })  : tagEffectivenessAvsB = tagEffectivenessAvsB ?? {},
        tagEffectivenessBvsA = tagEffectivenessBvsA ?? {},
        effectivenessAvsB = effectivenessAvsB ?? [],
        effectivenessBvsA = effectivenessBvsA ?? [];

  /// Разворачивает матрицу по тегам в полную матрицу по юнитам
  /// Вызывается явно, когда пользователь хочет синхронизировать матрицы
  void expandTagMatrices() {
    if (sideA.isEmpty || sideB.isEmpty) {
      effectivenessAvsB = [];
      effectivenessBvsA = [];
      return;
    }

    // A vs B
    effectivenessAvsB = List.generate(
      sideA.length,
      (i) => List.generate(
        sideB.length,
        (j) {
          final attTag = sideA[i].tag.isEmpty ? 'пехота' : sideA[i].tag;
          final defTag = sideB[j].tag.isEmpty ? 'пехота' : sideB[j].tag;
          return tagEffectivenessAvsB[attTag]?[defTag] ?? 1.0;
        },
      ),
    );

    // B vs A
    effectivenessBvsA = List.generate(
      sideB.length,
      (i) => List.generate(
        sideA.length,
        (j) {
          final attTag = sideB[i].tag.isEmpty ? 'пехота' : sideB[i].tag;
          final defTag = sideA[j].tag.isEmpty ? 'пехота' : sideA[j].tag;
          return tagEffectivenessBvsA[attTag]?[defTag] ?? 1.0;
        },
      ),
    );
  }

  /// Инициализирует полные матрицы единицами (по размерам юнитов)
  /// Используется при добавлении/удалении юнитов для сохранения ручной настройки
  void resizeEffectivenessMatrices({double fillValue = 1.0}) {
    final m = sideA.length;
    final n = sideB.length;
    
    if (m == 0 || n == 0) {
      effectivenessAvsB = [];
      effectivenessBvsA = [];
      return;
    }
    
    // Сохраняем старые значения
    final oldAvsB = List<List<double>>.from(
      effectivenessAvsB.map((row) => List<double>.from(row)));
    final oldBvsA = List<List<double>>.from(
      effectivenessBvsA.map((row) => List<double>.from(row)));
    
    // Создаём новые матрицы
    effectivenessAvsB = List.generate(m, (i) {
      if (i < oldAvsB.length) {
        final oldRow = oldAvsB[i];
        return List<double>.filled(n, fillValue)..setAll(0, oldRow.take(n));
      }
      return List<double>.filled(n, fillValue);
    });
    
    effectivenessBvsA = List.generate(n, (i) {
      if (i < oldBvsA.length) {
        final oldRow = oldBvsA[i];
        return List<double>.filled(m, fillValue)..setAll(0, oldRow.take(m));
      }
      return List<double>.filled(m, fillValue);
    });
  }

  @Deprecated('Используйте expandTagMatrices() или resizeEffectivenessMatrices()')
  void updateMatrixSize() {
    resizeEffectivenessMatrices();
  }

  Map<String, dynamic> toJson() {
    return {
      'side_a': sideA.map((u) => u.toJson()).toList(),
      'side_b': sideB.map((u) => u.toJson()).toList(),
      
      // === Сериализуем ОБЕ матрицы ===
      'tag_effectiveness_a_vs_b': {
        for (final entry in tagEffectivenessAvsB.entries)
          entry.key: Map.from(entry.value),
      },
      'tag_effectiveness_b_vs_a': {
        for (final entry in tagEffectivenessBvsA.entries)
          entry.key: Map.from(entry.value),
      },
      'effectiveness_a_vs_b': effectivenessAvsB,
      'effectiveness_b_vs_a': effectivenessBvsA,
      
      'morale': {
        'debaff_a': moralDebaffA,
        'debaff_b': moralDebaffB,
        'epsilon_success': epsilonSuccess,
      },
      'morale_influence': {
        'gamma_att': gammaAtt,
        'gamma_exp': gammaExp,
        'epsilon_exp': epsilonExp,
      },
      'uav_params': {
        'kappa_uav': kappaUav,
        'lambda_tech': lambdaTech,
        'lambda_use': lambdaUse,
      },
      'scaling': {
        'd_ref': dRef,
        'p_scale': pScale,
        's_min': sMin,
        's_max': sMax,
      },
      'integration': {
        'dt': dt,
        'steps': steps,
        'tolerance': tolerance,
        'max_newton_iter': maxNewtonIter,
      },
    };
  }

  factory CombatParams.fromJson(Map<String, dynamic> json) {
    final params = CombatParams(
      sideA: (json['side_a'] as List?)
              ?.map((u) => UnitType.fromJson(u))
              .toList() ?? [],
      sideB: (json['side_b'] as List?)
              ?.map((u) => UnitType.fromJson(u))
              .toList() ?? [],
      // === Загружаем матрицы по тегам ===
      tagEffectivenessAvsB: _parseTagMatrix(json['tag_effectiveness_a_vs_b']),
      tagEffectivenessBvsA: _parseTagMatrix(json['tag_effectiveness_b_vs_a']),
      // === Загружаем полные матрицы (если есть) ===
      effectivenessAvsB: _parseFullMatrix(json['effectiveness_a_vs_b']),
      effectivenessBvsA: _parseFullMatrix(json['effectiveness_b_vs_a']),
    );
    
    // === Если полные матрицы пусты — разворачиваем из тегов ===
    if (params.effectivenessAvsB.isEmpty && 
        params.sideA.isNotEmpty && 
        params.sideB.isNotEmpty) {
      params.expandTagMatrices();
    }
    
    // === Мораль ===
    final morale = json['morale'] as Map<String, dynamic>?;
    if (morale != null) {
      params.moralDebaffA = (morale['debaff_a'] ?? 0.01).toDouble();
      params.moralDebaffB = (morale['debaff_b'] ?? 0.01).toDouble();
      params.epsilonSuccess = (morale['epsilon_success'] ?? 0.5).toDouble();
    }
    
    // === Влияние морали ===
    final moraleInf = json['morale_influence'] as Map<String, dynamic>?;
    if (moraleInf != null) {
      params.gammaAtt = (moraleInf['gamma_att'] ?? 1.0).toDouble();
      params.gammaExp = (moraleInf['gamma_exp'] ?? 1.0).toDouble();
      params.epsilonExp = (moraleInf['epsilon_exp'] ?? 0.05).toDouble();
    }
    
    // === Параметры БПЛА ===
    final uavParams = json['uav_params'] as Map<String, dynamic>?;
    if (uavParams != null) {
      params.kappaUav = (uavParams['kappa_uav'] ?? 0.5).toDouble();
      params.lambdaTech = (uavParams['lambda_tech'] ?? 0.01).toDouble();
      params.lambdaUse = (uavParams['lambda_use'] ?? 0.15).toDouble();
    }
    
    // === Масштабирование ===
    final scaling = json['scaling'] as Map<String, dynamic>?;
    if (scaling != null) {
      params.dRef = (scaling['d_ref'] ?? 1000.0).toDouble();
      params.pScale = (scaling['p_scale'] ?? 1.6).toDouble();
      params.sMin = (scaling['s_min'] ?? 0.0001).toDouble();
      params.sMax = (scaling['s_max'] ?? 1.0).toDouble();
    }
    
    // === Интегрирование ===
    final integration = json['integration'] as Map<String, dynamic>?;
    if (integration != null) {
      params.dt = (integration['dt'] ?? 0.01).toDouble();
      params.steps = integration['steps'] ?? 1000;
      params.tolerance = (integration['tolerance'] ?? 1e-6).toDouble();
      params.maxNewtonIter = integration['max_newton_iter'] ?? 15000;
    }
    
    return params;
  }
  
  /// Вспомогательный метод для парсинга матрицы тегов из JSON
  static Map<String, Map<String, double>> _parseTagMatrix(dynamic json) {
    if (json == null) return {};
    
    final result = <String, Map<String, double>>{};
    final map = json as Map<String, dynamic>;
    
    for (final entry in map.entries) {
      final defenderMap = entry.value as Map<String, dynamic>;
      result[entry.key] = {
        for (final defEntry in defenderMap.entries)
          defEntry.key: (defEntry.value as num).toDouble(),
      };
    }
    
    return result;
  }
  
  /// Вспомогательный метод для парсинга полной матрицы из JSON
  static List<List<double>> _parseFullMatrix(dynamic json) {
    if (json == null) return [];
    
    return (json as List)
        .map((row) => (row as List).map((e) => (e as num).toDouble()).toList())
        .toList();
  }
}