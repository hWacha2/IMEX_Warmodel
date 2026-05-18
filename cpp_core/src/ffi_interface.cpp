#include "ffi_interface.h"
#include "types.h"
#include "solver.h"
#include "file_io.h"
#include <map>
#include <vector>
#include <string>
#include <algorithm>

// Хранилище результатов
static std::map<void*, combat_model::SimulationResults*> g_results_store;
static int g_results_counter = 0;

// ─────────────────────────────────────────────────────────────
// 🚀 ЕДИНСТВЕННАЯ функция запуска
// ─────────────────────────────────────────────────────────────
EXPORT void* run_simulation(
    // Side A
    int countA,
    const char** namesA,
    double* countsA, double* powersA, double* defensesA,
    double* moralesA, double* suppliesA,
    double* moraleDecaysA, double* supplyDecaysA,
    double* cpSupplySensA, bool* isUavA, bool* isFpvA,
    
    // Side B
    int countB,
    const char** namesB,
    double* countsB, double* powersB, double* defensesB,
    double* moralesB, double* suppliesB,
    double* moraleDecaysB, double* supplyDecaysB,
    double* cpSupplySensB, bool* isUavB, bool* isFpvB,
    
    // Matrices
    double* effectivenessAvsB,
    double* effectivenessBvsA,
    
    // Globals (16 параметров)
    double moral_debaffA,
    double moral_debaffB,
    double epsilon_success,
    double gamma_att,
    double gamma_exp,
    double epsilon_exp,
    double kappa_uav,
    double lambda_tech,
    double lambda_use,
    double dt,
    int steps,
    double tolerance,
    int max_newton_iter,
    double d_ref,
    double p_scale,
    double S_min,
    double S_max
) {
    // 1. Собираем CombatParams
    combat_model::CombatParams params;
    
    // Глобальные параметры морали
    params.moral_debaffA = moral_debaffA;
    params.moral_debaffB = moral_debaffB;
    params.epsilon_success = epsilon_success;
    
    // Параметры влияния морали
    params.gamma_att = gamma_att;
    params.gamma_exp = gamma_exp;
    params.epsilon_exp = epsilon_exp;
    
    // === НОВОЕ: Параметры БПЛА ===
    params.kappa_uav = kappa_uav;
    params.lambda_tech = lambda_tech;
    params.lambda_use = lambda_use;
    
    // Параметры интегрирования
    params.dt = dt;
    params.steps = steps;
    params.tolerance = tolerance;
    params.max_newton_iter = max_newton_iter;
    params.d_ref = d_ref;
    params.p_scale = p_scale;
    params.S_min = S_min;
    params.S_max = S_max;
    
    // Side A
    params.sideA.resize(countA);
    for (int i = 0; i < countA; ++i) {
        auto& u = params.sideA[i];
        u.name = namesA[i] ? std::string(namesA[i]) : "";
        u.count = countsA[i];
        u.combat_power = powersA[i];
        u.defense = defensesA[i];
        u.morale = moralesA[i];
        u.supply = suppliesA[i];
        u.morale_decay = moraleDecaysA[i];
        u.supply_decay = supplyDecaysA[i];
        
        // === НОВОЕ: Индивидуальная чувствительность и теги ===
        u.cp_supply_sensitivity = cpSupplySensA ? cpSupplySensA[i] : 0.3;
        u.is_uav = isUavA ? isUavA[i] : false;
        u.is_fpv = isFpvA ? isFpvA[i] : false;
    }
    
    // Side B
    params.sideB.resize(countB);
    for (int i = 0; i < countB; ++i) {
        auto& u = params.sideB[i];
        u.name = namesB[i] ? std::string(namesB[i]) : "";
        u.count = countsB[i];
        u.combat_power = powersB[i];
        u.defense = defensesB[i];
        u.morale = moralesB[i];
        u.supply = suppliesB[i];
        u.morale_decay = moraleDecaysB[i];
        u.supply_decay = supplyDecaysB[i];
        
        // === НОВОЕ ===
        u.cp_supply_sensitivity = cpSupplySensB ? cpSupplySensB[i] : 0.3;
        u.is_uav = isUavB ? isUavB[i] : false;
        u.is_fpv = isFpvB ? isFpvB[i] : false;
    }
    
    // Матрицы эффективности
    params.effectivenessAvsB.resize(countA, std::vector<double>(countB, 1.0));
    params.effectivenessBvsA.resize(countB, std::vector<double>(countA, 1.0));
    
    for (int i = 0; i < countA; ++i) {
        for (int j = 0; j < countB; ++j) {
            if (effectivenessAvsB) {
                params.effectivenessAvsB[i][j] = effectivenessAvsB[i * countB + j];
            }
            if (effectivenessBvsA) {
                params.effectivenessBvsA[j][i] = effectivenessBvsA[j * countA + i];
            }
        }
    }
    
    // 2. Запускаем решатель
    combat_model::IMEXSolver solver(params);
    auto* results = new combat_model::SimulationResults(solver.solve());
    
    // 3. Сохраняем в хранилище и возвращаем хендл
    void* handle = reinterpret_cast<void*>(static_cast<intptr_t>(++g_results_counter));
    g_results_store[handle] = results;
    
    return handle;
}

// ─────────────────────────────────────────────────────────────
// 🧹 Очистка
// ─────────────────────────────────────────────────────────────
EXPORT void results_destroy(void* results_ptr) {
    auto it = g_results_store.find(results_ptr);
    if (it != g_results_store.end()) {
        delete it->second;
        g_results_store.erase(it);
    }
}

// ─────────────────────────────────────────────────────────────
// 📊 Геттеры результатов
// ─────────────────────────────────────────────────────────────
#define SAFE_GET(results_ptr, field, default_val) \
    auto it_##field = g_results_store.find(results_ptr); \
    if (it_##field == g_results_store.end()) return default_val; \
    auto* res_##field = it_##field->second;

#define RESULTS_GETTER_2D(name, field) \
EXPORT double results_get_##name(void* results_ptr, int type_idx, int time_idx) { \
    SAFE_GET(results_ptr, field, 0.0); \
    if (type_idx < 0 || time_idx < 0) return 0.0; \
    if (type_idx >= static_cast<int>(res_##field->field.size())) return 0.0; \
    if (time_idx >= static_cast<int>(res_##field->field[type_idx].size())) return 0.0; \
    return res_##field->field[type_idx][time_idx]; \
}

EXPORT int results_get_time_count(void* results_ptr) {
    SAFE_GET(results_ptr, time, 0);
    return static_cast<int>(res_time->time.size());
}

EXPORT double results_get_time(void* results_ptr, int index) {
    SAFE_GET(results_ptr, time, 0.0);
    if (index < 0 || index >= static_cast<int>(res_time->time.size())) return 0.0;
    return res_time->time[index];
}

EXPORT int results_get_type_count_a(void* results_ptr) {
    SAFE_GET(results_ptr, A_counts, 0);
    return static_cast<int>(res_A_counts->A_counts.size());
}

EXPORT int results_get_type_count_b(void* results_ptr) {
    SAFE_GET(results_ptr, B_counts, 0);
    return static_cast<int>(res_B_counts->B_counts.size());
}

// Генерируем все 2D-геттеры
RESULTS_GETTER_2D(a_count, A_counts)
RESULTS_GETTER_2D(b_count, B_counts)
RESULTS_GETTER_2D(a_morale, A_morale)
RESULTS_GETTER_2D(b_morale, B_morale)
RESULTS_GETTER_2D(a_supply, A_supply)
RESULTS_GETTER_2D(b_supply, B_supply)
RESULTS_GETTER_2D(a_attack, A_attack)
RESULTS_GETTER_2D(b_attack, B_attack)
RESULTS_GETTER_2D(a_exposure, A_exposure)
RESULTS_GETTER_2D(b_exposure, B_exposure)

// === НОВОЕ: Геттеры для активности БПЛА ===
EXPORT double results_get_uav_activity_a(void* results_ptr, int time_idx) {
    SAFE_GET(results_ptr, UAV_activity_A, 0.0);
    if (time_idx < 0 || time_idx >= static_cast<int>(res_UAV_activity_A->UAV_activity_A.size())) return 0.0;
    return res_UAV_activity_A->UAV_activity_A[time_idx];
}

EXPORT double results_get_uav_activity_b(void* results_ptr, int time_idx) {
    SAFE_GET(results_ptr, UAV_activity_B, 0.0);
    if (time_idx < 0 || time_idx >= static_cast<int>(res_UAV_activity_B->UAV_activity_B.size())) return 0.0;
    return res_UAV_activity_B->UAV_activity_B[time_idx];
}

// Простые геттеры
EXPORT int results_get_total_iterations(void* results_ptr) {
    SAFE_GET(results_ptr, total_iterations, 0);
    return res_total_iterations->total_iterations;
}

EXPORT int results_get_convergence_failures(void* results_ptr) {
    SAFE_GET(results_ptr, convergence_failures, 0);
    return res_convergence_failures->convergence_failures;
}

EXPORT double results_get_execution_time_ms(void* results_ptr) {
    SAFE_GET(results_ptr, execution_time_ms, 0.0);
    return res_execution_time_ms->execution_time_ms;
}

EXPORT double results_get_initial_force_a(void* results_ptr) {
    SAFE_GET(results_ptr, initial_force_A, 0.0);
    return res_initial_force_A->initial_force_A;
}

EXPORT double results_get_initial_force_b(void* results_ptr) {
    SAFE_GET(results_ptr, initial_force_B, 0.0);
    return res_initial_force_B->initial_force_B;
}

EXPORT double results_get_final_force_a(void* results_ptr) {
    SAFE_GET(results_ptr, final_force_A, 0.0);
    return res_final_force_A->final_force_A;
}

EXPORT double results_get_final_force_b(void* results_ptr) {
    SAFE_GET(results_ptr, final_force_B, 0.0);
    return res_final_force_B->final_force_B;
}

EXPORT int results_get_winner(void* results_ptr) {
    SAFE_GET(results_ptr, winner, 0);
    return res_winner->winner;
}

EXPORT double results_get_avg_newton_iterations(void* results_ptr) {
    SAFE_GET(results_ptr, avg_newton_iterations, 0.0);
    return res_avg_newton_iterations->avg_newton_iterations;
}

EXPORT int results_get_max_newton_iterations(void* results_ptr) {
    SAFE_GET(results_ptr, max_newton_iterations, 0);
    return res_max_newton_iterations->max_newton_iterations;
}

// ─────────────────────────────────────────────────────────────
// 💾 Экспорт в CSV
// ─────────────────────────────────────────────────────────────
EXPORT bool results_export_to_csv(
    void* results_ptr,
    const char* filepath,
    const char** unit_names_a, int unit_count_a,
    const char** unit_names_b, int unit_count_b
) {
    SAFE_GET(results_ptr, time, false);
    
    std::vector<std::string> names_a, names_b;
    for (int i = 0; i < unit_count_a; ++i) {
        names_a.push_back(unit_names_a[i] ? std::string(unit_names_a[i]) : "");
    }
    for (int i = 0; i < unit_count_b; ++i) {
        names_b.push_back(unit_names_b[i] ? std::string(unit_names_b[i]) : "");
    }
    
    return combat_model::FileIO::export_results_to_csv(
        *res_time, std::string(filepath), names_a, names_b);
}