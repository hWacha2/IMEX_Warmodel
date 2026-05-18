#pragma once
#include <vector>
#include <string>

namespace combat_model {

struct UnitType {
    std::string name;
    double count;
    double combat_power;
    double defense;
    double morale;
    double supply;
    double morale_decay;
    double supply_decay;
    double cp_supply_sensitivity;  // Чувствительность боевой мощи к снабжению
    
    // === НОВОЕ: Теги для БПЛА и FPV ===
    bool is_uav;   // Разведывательный БПЛА (влияет на уязвимость врага)
    bool is_fpv;   // Ударный FPV-дрон (наносит урон, расходуется)
    
    UnitType() : count(0), combat_power(1.0), defense(1.0), 
                 morale(1.0), supply(1.0), 
                 morale_decay(0.01), supply_decay(0.01),
                 cp_supply_sensitivity(0.3),
                 is_uav(false), is_fpv(false) {}
};

struct CombatParams {
    std::vector<UnitType> sideA;
    std::vector<UnitType> sideB;
    std::vector<std::vector<double>> effectivenessAvsB;
    std::vector<std::vector<double>> effectivenessBvsA;
    
    // Параметры морали
    double moral_debaffA = 0.01;
    double moral_debaffB = 0.01;
    double epsilon_success = 0.5;  // Влияние успехов противника на мораль
    
    // Параметры влияния морали на боеспособность
    double gamma_att = 1.0;   // Влияние морали на атаку
    double gamma_exp = 1.0;   // Влияние морали на уязвимость
    double epsilon_exp = 0.05; // Базовая уязвимость
    
    // Параметры снабжения
    double cp_supply_sensitivity = 0.0;  // Глобальный (устаревший, используйте в UnitType)
    
    // === НОВОЕ: Параметры БПЛА/FPV ===
    double kappa_uav = 0.5;      // Влияние превосходства в БПЛА на уязвимость
    double lambda_tech = 0.01;   // Техдеградация разведывательных БПЛА
    double lambda_use = 0.15;    // Боевое расходование FPV-дронов
    
    // Параметры масштабирования коэффициентов потерь
    double dt = 0.01;
    int steps = 1000;
    double tolerance = 1e-6;
    int max_newton_iter = 15000;
    double d_ref = 1000.0;
    double p_scale = 1.6;
    double S_min = 0.0001;
    double S_max = 1.0;
    
    CombatParams() {}
};

struct SimulationResults {
    std::vector<double> time;
    std::vector<std::vector<double>> A_counts;
    std::vector<std::vector<double>> B_counts;
    std::vector<std::vector<double>> A_morale;
    std::vector<std::vector<double>> B_morale;
    std::vector<std::vector<double>> A_supply;
    std::vector<std::vector<double>> B_supply;
    std::vector<std::vector<double>> A_attack;
    std::vector<std::vector<double>> B_attack;
    std::vector<std::vector<double>> A_exposure;
    std::vector<std::vector<double>> B_exposure;
    
    // === НОВОЕ: Активность БПЛА ===
    std::vector<double> UAV_activity_A;  // U_A(t) для каждого шага
    std::vector<double> UAV_activity_B;  // U_B(t) для каждого шага
    
    int total_iterations = 0;
    int convergence_failures = 0;
    double execution_time_ms = 0.0;
    double initial_force_A = 0.0;
    double initial_force_B = 0.0;
    double final_force_A = 0.0;
    double final_force_B = 0.0;
    int winner = 0;

    double avg_newton_iterations = 0.0;
    int max_newton_iterations = 0;
};

} // namespace combat_model