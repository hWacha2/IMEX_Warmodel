class UnitType {
  String name;
  double count;
  double combatPower;
  double defense;
  double morale;
  double supply;
  double moraleDecay;
  double supplyDecay;
  
  // === НОВОЕ: Индивидуальная чувствительность к снабжению ===
  double cpSupplySensitivity;
  
  // === НОВОЕ: Теги для БПЛА и FPV ===
  bool isUav;   // Разведывательный БПЛА (влияет на уязвимость врага)
  bool isFpv;   // Ударный FPV-дрон (наносит урон, расходуется)

  UnitType({
    required this.name,
    this.count = 0.0,
    this.combatPower = 1.0,
    this.defense = 1.0,
    this.morale = 1.0,
    this.supply = 1.0,
    this.moraleDecay = 0.01,
    this.supplyDecay = 0.01,
    this.cpSupplySensitivity = 0.3,  // Значение по умолчанию
    this.isUav = false,
    this.isFpv = false,
  });

  UnitType copyWith({
    String? name,
    double? count,
    double? combatPower,
    double? defense,
    double? morale,
    double? supply,
    double? moraleDecay,
    double? supplyDecay,
    double? cpSupplySensitivity,
    bool? isUav,
    bool? isFpv,
  }) {
    return UnitType(
      name: name ?? this.name,
      count: count ?? this.count,
      combatPower: combatPower ?? this.combatPower,
      defense: defense ?? this.defense,
      morale: morale ?? this.morale,
      supply: supply ?? this.supply,
      moraleDecay: moraleDecay ?? this.moraleDecay,
      supplyDecay: supplyDecay ?? this.supplyDecay,
      cpSupplySensitivity: cpSupplySensitivity ?? this.cpSupplySensitivity,
      isUav: isUav ?? this.isUav,
      isFpv: isFpv ?? this.isFpv,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'count': count,
      'combat_power': combatPower,
      'defense': defense,
      'morale': morale,
      'supply': supply,
      'morale_decay': moraleDecay,
      'supply_decay': supplyDecay,
      // === НОВОЕ ===
      'cp_supply_sensitivity': cpSupplySensitivity,
      'is_uav': isUav,
      'is_fpv': isFpv,
    };
  }

  factory UnitType.fromJson(Map<String, dynamic> json) {
    return UnitType(
      name: json['name'] ?? 'Пехота',
      count: (json['count'] ?? 0.0).toDouble(),
      combatPower: (json['combat_power'] ?? 1.0).toDouble(),
      defense: (json['defense'] ?? 1.0).toDouble(),
      morale: (json['morale'] ?? 1.0).toDouble(),
      supply: (json['supply'] ?? 1.0).toDouble(),
      moraleDecay: (json['morale_decay'] ?? 0.01).toDouble(),
      supplyDecay: (json['supply_decay'] ?? 0.01).toDouble(),
      // === НОВОЕ с безопасными значениями по умолчанию ===
      cpSupplySensitivity: (json['cp_supply_sensitivity'] ?? 0.3).toDouble(),
      isUav: json['is_uav'] ?? false,
      isFpv: json['is_fpv'] ?? false,
    );
  }
}