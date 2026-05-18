#pragma once
#include "types.h"
#include "matrix.h"
#include <vector>
#include <chrono>

namespace combat_model {

class IMEXSolver {
public:
    explicit IMEXSolver(const CombatParams& params);
    SimulationResults solve();
    
private:
    CombatParams params_;
    size_t M_;
    size_t N_;
    size_t state_size_;
    std::vector<double> y0_;
    
    double alpha_scaled_;
    double beta_scaled_;
    
    // Вспомогательные методы
    void extract_state(const std::vector<double>& y,
                      std::vector<double>& A, std::vector<double>& B,
                      std::vector<double>& A_morale, std::vector<double>& B_morale,
                      std::vector<double>& A_supply, std::vector<double>& B_supply) const;
    
    void project_to_feasible(std::vector<double>& y) const;
    
    // === ИСПРАВЛЕНО: сигнатура с параметрами U_A, U_B ===
    void rhs_split(const std::vector<double>& y,
                   std::vector<double>& f_vec,
                   std::vector<double>& g_vec,
                   double& U_A, double& U_B) const;
    
    std::vector<double> explicit_rk2_step(const std::vector<double>& y_n, double dt) const;
    
    std::vector<double> implicit_cn_step(const std::vector<double>& y_exp, 
                                        const std::vector<double>& g_n, 
                                        double dt, 
                                        int& fail_count, 
                                        int& out_newton_iterations) const;
    
    Matrix compute_jacobian_g(const std::vector<double>& y, double dt) const;
    
    // === ИСПРАВЛЕНО: сигнатура с параметрами U_A, U_B ===
    void compute_metrics(const std::vector<double>& y,
                        std::vector<double>& A_attack,
                        std::vector<double>& B_attack,
                        std::vector<double>& A_exposure,
                        std::vector<double>& B_exposure,
                        double& U_A, double& U_B) const;
    
    // Вспомогательные функции для БПЛА
    double compute_uav_activity(const std::vector<double>& counts,
                               const std::vector<double>& supplies,
                               const std::vector<UnitType>& units) const;
    
    double compute_uav_advantage(double U_A, double U_B) const;
};

} // namespace combat_model