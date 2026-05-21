// lib/models/unit_type.dart
class UnitType {
  String name;
  String tag;  // ← Привязка к универсальному тегу
  double count;
  double combatPower;
  double defense;
  double morale;
  double supply;
  double moraleDecay;
  double supplyDecay;
  
  // === Индивидуальная чувствительность к снабжению ===
  double cpSupplySensitivity;
  
  // === Теги для БПЛА и FPV ===
  bool isUav;   // Разведывательный БПЛА
  bool isFpv;   // Ударный FPV-дрон

  UnitType({
    required this.name,
    this.tag = 'пехота',  // ← Дефолтное значение
    this.count = 0.0,
    this.combatPower = 1.0,
    this.defense = 1.0,
    this.morale = 1.0,
    this.supply = 1.0,
    this.moraleDecay = 0.01,
    this.supplyDecay = 0.01,
    this.cpSupplySensitivity = 0.3,
    this.isUav = false,
    this.isFpv = false,
  });

  UnitType copyWith({
    String? name,
    String? tag,  // ← Добавлено
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
      tag: tag ?? this.tag,  // ← Добавлено
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
      'tag': tag,  // ← НОВОЕ: сохраняем тег
      'count': count,
      'combat_power': combatPower,
      'defense': defense,
      'morale': morale,
      'supply': supply,
      'morale_decay': moraleDecay,
      'supply_decay': supplyDecay,
      'cp_supply_sensitivity': cpSupplySensitivity,
      'is_uav': isUav,
      'is_fpv': isFpv,
    };
  }

  factory UnitType.fromJson(Map<String, dynamic> json) {
    return UnitType(
      name: json['name'] ?? 'Пехота',
      tag: json['tag'] ?? 'пехота',  // ← НОВОЕ: загружаем тег с дефолтом
      count: (json['count'] ?? 0.0).toDouble(),
      combatPower: (json['combat_power'] ?? 1.0).toDouble(),
      defense: (json['defense'] ?? 1.0).toDouble(),
      morale: (json['morale'] ?? 1.0).toDouble(),
      supply: (json['supply'] ?? 1.0).toDouble(),
      moraleDecay: (json['morale_decay'] ?? 0.01).toDouble(),
      supplyDecay: (json['supply_decay'] ?? 0.01).toDouble(),
      cpSupplySensitivity: (json['cp_supply_sensitivity'] ?? 0.3).toDouble(),
      isUav: json['is_uav'] ?? false,
      isFpv: json['is_fpv'] ?? false,
    );
  }
}