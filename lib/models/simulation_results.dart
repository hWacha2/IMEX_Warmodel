class SimulationResults {
  List<double> time;
  List<List<double>> aCounts;
  List<List<double>> bCounts;
  List<List<double>> aMorale;
  List<List<double>> bMorale;
  List<List<double>> aSupply;
  List<List<double>> bSupply;
  
  // === НОВОЕ: Активность БПЛА для визуализации ===
  List<double> uavActivityA;
  List<double> uavActivityB;

  double executionTimeMs;
  int totalIterations;
  int convergenceFailures;
  double initialForceA;
  double initialForceB;
  double finalForceA;
  double finalForceB;
  int winner; // 0=ничья, 1=A, 2=B
  double avgNewtonIterations;
  int maxNewtonIterations;

  SimulationResults({
    this.time = const [],
    this.aCounts = const [],
    this.bCounts = const [],
    this.aMorale = const [],
    this.bMorale = const [],
    this.aSupply = const [],
    this.bSupply = const [],
    this.uavActivityA = const [],  // === НОВОЕ ===
    this.uavActivityB = const [],  // === НОВОЕ ===
    this.executionTimeMs = 0.0,
    this.totalIterations = 0,
    this.convergenceFailures = 0,
    this.initialForceA = 0.0,
    this.initialForceB = 0.0,
    this.finalForceA = 0.0,
    this.finalForceB = 0.0,
    this.winner = 0,
    this.avgNewtonIterations = 0.0,
    this.maxNewtonIterations = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'version': '1.1',  // Обновлённая версия формата
      'time': time,
      'aCounts': aCounts,
      'bCounts': bCounts,
      'aMorale': aMorale,
      'bMorale': bMorale,
      'aSupply': aSupply,
      'bSupply': bSupply,
      // === НОВОЕ: активность БПЛА ===
      'uavActivityA': uavActivityA,
      'uavActivityB': uavActivityB,
      'executionTimeMs': executionTimeMs,
      'totalIterations': totalIterations,
      'convergenceFailures': convergenceFailures,
      'initialForceA': initialForceA,
      'initialForceB': initialForceB,
      'finalForceA': finalForceA,
      'finalForceB': finalForceB,
      'winner': winner,
      'avgNewtonIterations': avgNewtonIterations,
      'maxNewtonIterations': maxNewtonIterations,
    };
  }

  factory SimulationResults.fromJson(Map<String, dynamic> json) {
    return SimulationResults(
      time: List<double>.from(json['time'] ?? []),
      aCounts: _parse2D(json['aCounts']),
      bCounts: _parse2D(json['bCounts']),
      aMorale: _parse2D(json['aMorale']),
      bMorale: _parse2D(json['bMorale']),
      aSupply: _parse2D(json['aSupply']),
      bSupply: _parse2D(json['bSupply']),
      // === НОВОЕ: активность БПЛА с безопасным парсингом ===
      uavActivityA: _parse1D(json['uavActivityA']),
      uavActivityB: _parse1D(json['uavActivityB']),
      executionTimeMs: (json['executionTimeMs'] ?? 0.0).toDouble(),
      totalIterations: json['totalIterations'] ?? 0,
      convergenceFailures: json['convergenceFailures'] ?? 0,
      initialForceA: (json['initialForceA'] ?? 0.0).toDouble(),
      initialForceB: (json['initialForceB'] ?? 0.0).toDouble(),
      finalForceA: (json['finalForceA'] ?? 0.0).toDouble(),
      finalForceB: (json['finalForceB'] ?? 0.0).toDouble(),
      winner: json['winner'] ?? 0,
      avgNewtonIterations: (json['avgNewtonIterations'] ?? 0.0).toDouble(),
      maxNewtonIterations: json['maxNewtonIterations'] ?? 0,
    );
  }

  static List<List<double>> _parse2D(dynamic json) {
    if (json == null) return [];
    return (json as List).map((row) => List<double>.from(row)).toList();
  }
  
  // === НОВОЕ: вспомогательный метод для 1D массивов ===
  static List<double> _parse1D(dynamic json) {
    if (json == null) return [];
    return List<double>.from(json as List);
  }
}