import 'unit_type.dart';

class CombatParams {
  List<UnitType> sideA;
  List<UnitType> sideB;
  List<List<double>> effectivenessAvsB;
  List<List<double>> effectivenessBvsA;
  
  // Параметры морали
  double moralDebaffA;
  double moralDebaffB;
  double epsilonSuccess;  // === НОВОЕ: влияние успехов противника на мораль ===
  
  // Параметры влияния морали на боеспособность
  double gammaAtt;
  double gammaExp;
  double epsilonExp;
  
  // === НОВОЕ: Параметры БПЛА/FPV ===
  double kappaUav;      // Влияние превосходства в БПЛА на уязвимость
  double lambdaTech;    // Техдеградация разведывательных БПЛА
  double lambdaUse;     // Боевое расходование FPV-дронов
  
  // Параметры масштабирования коэффициентов потерь
  double dRef;
  double pScale;
  double sMin;          // === НОВОЕ: границы масштабирования ===
  double sMax;
  
  // Параметры интегрирования
  double dt;
  int steps;
  double tolerance;
  int maxNewtonIter;

  CombatParams({
    this.sideA = const [],
    this.sideB = const [],
    List<List<double>>? effectivenessAvsB,
    List<List<double>>? effectivenessBvsA,
    this.moralDebaffA = 0.01,
    this.moralDebaffB = 0.01,
    this.epsilonSuccess = 0.5,  // === НОВОЕ: значение по умолчанию ===
    this.gammaAtt = 1.0,
    this.gammaExp = 1.0,
    this.epsilonExp = 0.05,
    this.kappaUav = 0.5,        // === НОВОЕ ===
    this.lambdaTech = 0.01,     // === НОВОЕ ===
    this.lambdaUse = 0.15,      // === НОВОЕ ===
    this.dRef = 1000.0,
    this.pScale = 1.6,
    this.sMin = 0.0001,         // === НОВОЕ ===
    this.sMax = 1.0,            // === НОВОЕ ===
    this.dt = 0.01,
    this.steps = 1000,
    this.tolerance = 1e-6,
    this.maxNewtonIter = 15000,
  })  : effectivenessAvsB = effectivenessAvsB ?? [],
        effectivenessBvsA = effectivenessBvsA ?? [];

  void updateMatrixSize() {
    final m = sideA.length;
    final n = sideB.length;
    
    // Resize AvsB (m x n)
    effectivenessAvsB = List.generate(m, (i) {
      if (i < effectivenessAvsB.length) {
        final row = effectivenessAvsB[i];
        return List.filled(n, 1.0)..setAll(0, row.take(n));
      }
      return List.filled(n, 1.0);
    });
    
    // Resize BvsA (n x m)
    effectivenessBvsA = List.generate(n, (i) {
      if (i < effectivenessBvsA.length) {
        final row = effectivenessBvsA[i];
        return List.filled(m, 1.0)..setAll(0, row.take(m));
      }
      return List.filled(m, 1.0);
    });
  }

  Map<String, dynamic> toJson() {
    return {
      'side_a': sideA.map((u) => u.toJson()).toList(),
      'side_b': sideB.map((u) => u.toJson()).toList(),
      'effectiveness_a_vs_b': effectivenessAvsB,
      'effectiveness_b_vs_a': effectivenessBvsA,
      'morale': {
        'debaff_a': moralDebaffA,
        'debaff_b': moralDebaffB,
        'epsilon_success': epsilonSuccess,  // === НОВОЕ ===
      },
      'morale_influence': {
        'gamma_att': gammaAtt,
        'gamma_exp': gammaExp,
        'epsilon_exp': epsilonExp,
      },
      'uav_params': {  // === НОВОЕ: группа параметров БПЛА ===
        'kappa_uav': kappaUav,
        'lambda_tech': lambdaTech,
        'lambda_use': lambdaUse,
      },
      'scaling': {
        'd_ref': dRef,
        'p_scale': pScale,
        's_min': sMin,  // === НОВОЕ ===
        's_max': sMax,  // === НОВОЕ ===
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
              .toList() ??
          [],
      sideB: (json['side_b'] as List?)
              ?.map((u) => UnitType.fromJson(u))
              .toList() ??
          [],
      effectivenessAvsB: (json['effectiveness_a_vs_b'] as List?)
        ?.map((row) => (row as List).map((e) => (e as num).toDouble()).toList())
        .toList() ?? [],
      effectivenessBvsA: (json['effectiveness_b_vs_a'] as List?)
        ?.map((row) => (row as List).map((e) => (e as num).toDouble()).toList())
        .toList() ?? [],
    );
    
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
}