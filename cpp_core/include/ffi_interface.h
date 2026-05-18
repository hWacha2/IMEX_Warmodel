#pragma once

#ifdef _WIN32
    #define EXPORT extern "C" __declspec(dllexport)
#else
    #define EXPORT extern "C"
#endif

// ─────────────────────────────────────────────────────────────
// 🚀 ЕДИНСТВЕННАЯ функция запуска симуляции
// ─────────────────────────────────────────────────────────────
EXPORT void* run_simulation(
    // === Side A ===
    int countA,
    const char** namesA,
    double* countsA, double* powersA, double* defensesA,
    double* moralesA, double* suppliesA,
    double* moraleDecaysA, double* supplyDecaysA,
    double* cpSupplySensA,  // === НОВОЕ: индивидуальная чувствительность к снабжению ===
    bool* isUavA,           // === НОВОЕ: тег разведывательного БПЛА ===
    bool* isFpvA,           // === НОВОЕ: тег ударного FPV-дрона ===
    
    // === Side B ===
    int countB,
    const char** namesB,
    double* countsB, double* powersB, double* defensesB,
    double* moralesB, double* suppliesB,
    double* moraleDecaysB, double* supplyDecaysB,
    double* cpSupplySensB,  // === НОВОЕ ===
    bool* isUavB,           // === НОВОЕ ===
    bool* isFpvB,           // === НОВОЕ ===
    
    // === Матрицы эффективности (плоские, row-major) ===
    double* effectivenessAvsB,  // [countA * countB]
    double* effectivenessBvsA,  // [countB * countA]
    
    // === Глобальные параметры (16 значений — +4 новых) ===
    double moral_debaffA,
    double moral_debaffB,
    double epsilon_success,     // === НОВОЕ: влияние успехов противника на мораль ===
    double gamma_att,
    double gamma_exp,
    double epsilon_exp,
    double kappa_uav,           // === НОВОЕ: влияние БПЛА на уязвимость ===
    double lambda_tech,         // === НОВОЕ: техдеградация разведывательных БПЛА ===
    double lambda_use,          // === НОВОЕ: боевое расходование FPV ===
    double dt,
    int steps,
    double tolerance,
    int max_newton_iter,
    double d_ref,
    double p_scale,
    double S_min,               // === НОВОЕ: границы масштабирования ===
    double S_max
);

// ─────────────────────────────────────────────────────────────
// 🧹 Очистка памяти результатов
// ─────────────────────────────────────────────────────────────
EXPORT void results_destroy(void* results_ptr);

// ─────────────────────────────────────────────────────────────
// 📊 Геттеры для чтения результатов
// ─────────────────────────────────────────────────────────────
EXPORT int results_get_time_count(void* results_ptr);
EXPORT int results_get_type_count_a(void* results_ptr);
EXPORT int results_get_type_count_b(void* results_ptr);

EXPORT double results_get_time(void* results_ptr, int index);

// Данные по типам войск: [type_index][time_index]
EXPORT double results_get_a_count(void* results_ptr, int type_idx, int time_idx);
EXPORT double results_get_b_count(void* results_ptr, int type_idx, int time_idx);
EXPORT double results_get_a_morale(void* results_ptr, int type_idx, int time_idx);
EXPORT double results_get_b_morale(void* results_ptr, int type_idx, int time_idx);
EXPORT double results_get_a_supply(void* results_ptr, int type_idx, int time_idx);
EXPORT double results_get_b_supply(void* results_ptr, int type_idx, int time_idx);
EXPORT double results_get_a_attack(void* results_ptr, int type_idx, int time_idx);
EXPORT double results_get_b_attack(void* results_ptr, int type_idx, int time_idx);
EXPORT double results_get_a_exposure(void* results_ptr, int type_idx, int time_idx);
EXPORT double results_get_b_exposure(void* results_ptr, int type_idx, int time_idx);

// === НОВОЕ: Активность БПЛА [time_index] ===
EXPORT double results_get_uav_activity_a(void* results_ptr, int time_idx);
EXPORT double results_get_uav_activity_b(void* results_ptr, int time_idx);

// Сводная статистика
EXPORT int results_get_total_iterations(void* results_ptr);
EXPORT int results_get_convergence_failures(void* results_ptr);
EXPORT double results_get_execution_time_ms(void* results_ptr);
EXPORT double results_get_initial_force_a(void* results_ptr);
EXPORT double results_get_initial_force_b(void* results_ptr);
EXPORT double results_get_final_force_a(void* results_ptr);
EXPORT double results_get_final_force_b(void* results_ptr);
EXPORT int results_get_winner(void* results_ptr);
EXPORT double results_get_avg_newton_iterations(void* results_ptr);
EXPORT int results_get_max_newton_iterations(void* results_ptr);

// ─────────────────────────────────────────────────────────────
// 💾 Экспорт в CSV
// ─────────────────────────────────────────────────────────────
EXPORT bool results_export_to_csv(
    void* results_ptr,
    const char* filepath,
    const char** unit_names_a, int unit_count_a,
    const char** unit_names_b, int unit_count_b
);