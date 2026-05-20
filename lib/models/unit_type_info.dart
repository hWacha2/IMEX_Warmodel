// lib/models/unit_type_info.dart
import '../models/unit_type.dart';
/// Метаданные типа войск (задаются при создании типа)
class UnitTypeInfo {
  final String tag;
  final bool isUav;   // Все отряды этого типа — разведывательные БПЛА
  final bool isFpv;   // Все отряды этого типа — ударные FPV-дроны

  UnitTypeInfo({
    required this.tag,
    this.isUav = false,
    this.isFpv = false,
  }) : assert(!(isUav && isFpv), 'Тип не может быть одновременно БПЛА и FPV');

  /// Создаёт новый отряд с параметрами этого типа
  UnitType createUnit({
    required String name,
    required double count,
    required double combatPower,
    required double defense,
    required double morale,
    required double supply,
    required double moraleDecay,
    required double supplyDecay,
    required double cpSupplySensitivity,
  }) {
    return UnitType(
      name: name,
   
      count: count,
      combatPower: isUav ? 0.0 : combatPower,  // БПЛА не наносят урон
      defense: isUav || isFpv ? 1.0 : defense, // Дроны имеют фикс. защиту
      morale: isUav || isFpv ? 1.0 : morale,   // Дроны имеют фикс. мораль
      supply: isFpv ? 1.0 : supply,            // FPV имеют фикс. снабжение
      moraleDecay: isUav || isFpv ? 0.0 : moraleDecay,
      supplyDecay: isFpv ? 0.0 : supplyDecay,
      cpSupplySensitivity: isFpv ? 0.0 : cpSupplySensitivity,
      isUav: isUav,
      isFpv: isFpv,
    );
  }

  Map<String, dynamic> toJson() => {
        'tag': tag,
        'is_uav': isUav,
        'is_fpv': isFpv,
      };

  factory UnitTypeInfo.fromJson(Map<String, dynamic> json) => UnitTypeInfo(
        tag: json['tag'] as String,
        isUav: json['is_uav'] as bool? ?? false,
        isFpv: json['is_fpv'] as bool? ?? false,
      );
}