#include "solver.h"
#include <cmath>
#include <algorithm>
#include <numeric>

namespace combat_model
{

    IMEXSolver::IMEXSolver(const CombatParams &params) : params_(params), M_(params.sideA.size()), N_(params.sideB.size())
    {
        state_size_ = 3 * M_ + 3 * N_;
        y0_.resize(state_size_);

        size_t idx = 0;
        for (size_t i = 0; i < M_; ++i)
            y0_[idx++] = params.sideA[i].count;
        for (size_t i = 0; i < N_; ++i)
            y0_[idx++] = params.sideB[i].count;
        for (size_t i = 0; i < M_; ++i)
            y0_[idx++] = params.sideA[i].morale;
        for (size_t i = 0; i < N_; ++i)
            y0_[idx++] = params.sideB[i].morale;
        for (size_t i = 0; i < M_; ++i)
            y0_[idx++] = params.sideA[i].supply;
        for (size_t i = 0; i < N_; ++i)
            y0_[idx++] = params.sideB[i].supply;

        // Масштабирование коэффициентов
        double total_initial = 0.0;
        for (const auto &u : params_.sideA)
            total_initial += u.count;
        for (const auto &u : params_.sideB)
            total_initial += u.count;
        if (total_initial < 1.0)
            total_initial = 1.0;

        double S = std::pow(params_.d_ref / total_initial, params_.p_scale);
        S = std::max(params_.S_min, std::min(S, params_.S_max));

        // === ИСПРАВЛЕНИЕ: считаем среднюю мощность ТОЛЬКО по основным войскам ===
        double avg_A_power = 0.0, avg_B_power = 0.0;
        int count_A_main = 0, count_B_main = 0;

        for (const auto &u : params_.sideA)
        {
            if (u.count > 0 && !u.is_uav && !u.is_fpv)
            {
                avg_A_power += u.combat_power;
                ++count_A_main;
            }
        }
        for (const auto &u : params_.sideB)
        {
            if (u.count > 0 && !u.is_uav && !u.is_fpv)
            {
                avg_B_power += u.combat_power;
                ++count_B_main;
            }
        }

        if (count_A_main > 0)
            avg_A_power /= count_A_main;
        else
            avg_A_power = 1.0; // защита от деления на ноль

        if (count_B_main > 0)
            avg_B_power /= count_B_main;
        else
            avg_B_power = 1.0;

        // Логирование для отладки
        // fprintf(stderr, "Средняя мощность (основные войска): A=%.3f, B=%.3f\n", avg_A_power, avg_B_power);

        const double base_scale = 0.015;
        double alpha_base = base_scale * (avg_B_power / std::max(avg_A_power, 1e-10));
        double beta_base = base_scale * (avg_A_power / std::max(avg_B_power, 1e-10));

        alpha_scaled_ = alpha_base * S;
        beta_scaled_ = beta_base * S;
    }

    void IMEXSolver::extract_state(const std::vector<double> &y,
                                   std::vector<double> &A, std::vector<double> &B,
                                   std::vector<double> &A_morale, std::vector<double> &B_morale,
                                   std::vector<double> &A_supply, std::vector<double> &B_supply) const
    {
        size_t idx = 0;
        A.resize(M_);
        for (size_t i = 0; i < M_; ++i)
            A[i] = y[idx++];
        B.resize(N_);
        for (size_t i = 0; i < N_; ++i)
            B[i] = y[idx++];
        A_morale.resize(M_);
        for (size_t i = 0; i < M_; ++i)
            A_morale[i] = y[idx++];
        B_morale.resize(N_);
        for (size_t i = 0; i < N_; ++i)
            B_morale[i] = y[idx++];
        A_supply.resize(M_);
        for (size_t i = 0; i < M_; ++i)
            A_supply[i] = y[idx++];
        B_supply.resize(N_);
        for (size_t i = 0; i < N_; ++i)
            B_supply[i] = y[idx++];
    }

    void IMEXSolver::project_to_feasible(std::vector<double> &y) const
    {
        size_t idx = 0;
        for (size_t i = 0; i < M_; ++i)
        {
            y[idx] = std::max(0.0, y[idx]);
            ++idx;
        }
        for (size_t i = 0; i < N_; ++i)
        {
            y[idx] = std::max(0.0, y[idx]);
            ++idx;
        }
        for (size_t i = 0; i < M_ + N_; ++i)
        {
            y[idx] = std::max(0.0, std::min(1.0, y[idx]));
            ++idx;
        }
        for (size_t i = 0; i < M_ + N_; ++i)
        {
            y[idx] = std::max(0.0, std::min(1.0, y[idx]));
            ++idx;
        }
    }

    // === ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ДЛЯ БПЛА ===
    double IMEXSolver::compute_uav_activity(const std::vector<double> &counts,
                                            const std::vector<double> &supplies,
                                            const std::vector<UnitType> &units) const
    {
        double activity = 0.0;
        for (size_t i = 0; i < units.size(); ++i)
        {
            if (units[i].is_uav)
            {
                // Формула (3.11): активность = численность × снабжение × эффективность снабжения
                // БЕЗ умножения на combat_power — БПЛА влияют на уязвимость независимо от урона
                double supply_eff = 1.0 - units[i].cp_supply_sensitivity * (1.0 - supplies[i]);
                activity += counts[i] * supplies[i] * supply_eff;
            }
        }
        return activity;
    }

    double IMEXSolver::compute_uav_advantage(double U_A, double U_B) const
    {
        const double delta = 1e-6;
        return U_B / (U_A + U_B + delta);
    }

    // === ИСПРАВЛЕННАЯ РЕАЛИЗАЦИЯ rhs_split ===
    void IMEXSolver::rhs_split(const std::vector<double> &y,
                               std::vector<double> &f_vec,
                               std::vector<double> &g_vec,
                               double &U_A, double &U_B) const
    {
        f_vec.assign(state_size_, 0.0);
        g_vec.assign(state_size_, 0.0);

        std::vector<double> A, B, A_m, B_m, A_s, B_s;
        extract_state(y, A, B, A_m, B_m, A_s, B_s);

        // Расчёт активности БПЛА
        U_A = compute_uav_activity(A, A_s, params_.sideA);
        U_B = compute_uav_activity(B, B_s, params_.sideB);

        double uav_adv_B = compute_uav_advantage(U_A, U_B);
        double uav_adv_A = compute_uav_advantage(U_B, U_A);

        // Эффективная боевая мощь с индивидуальной чувствительностью
        std::vector<double> A_cp_eff(M_), B_cp_eff(N_);
        for (size_t i = 0; i < M_; ++i)
            A_cp_eff[i] = params_.sideA[i].combat_power * (1.0 - params_.sideA[i].cp_supply_sensitivity * (1.0 - A_s[i]));
        for (size_t j = 0; j < N_; ++j)
            B_cp_eff[j] = params_.sideB[j].combat_power * (1.0 - params_.sideB[j].cp_supply_sensitivity * (1.0 - B_s[j]));

        // Атакующая способность и базовая уязвимость
        std::vector<double> A_atk(M_), B_atk(N_), A_exp_base(M_), B_exp_base(N_);
        for (size_t i = 0; i < M_; ++i)
        {
            A_atk[i] = A[i] * A_cp_eff[i] * std::pow(A_m[i], params_.gamma_att);
            A_exp_base[i] = params_.epsilon_exp + std::pow(1.0 - A_m[i], params_.gamma_exp);
        }
        for (size_t j = 0; j < N_; ++j)
        {
            B_atk[j] = B[j] * B_cp_eff[j] * std::pow(B_m[j], params_.gamma_att);
            B_exp_base[j] = params_.epsilon_exp + std::pow(1.0 - B_m[j], params_.gamma_exp);
        }

        // Модифицированная уязвимость с учётом БПЛА
        std::vector<double> A_exp(M_), B_exp(N_);
        for (size_t i = 0; i < M_; ++i)
        {
            double mod_factor = 1.0 + params_.kappa_uav * uav_adv_B;
            A_exp[i] = A[i] * A_exp_base[i] * mod_factor;
        }
        for (size_t j = 0; j < N_; ++j)
        {
            double mod_factor = 1.0 + params_.kappa_uav * uav_adv_A;
            B_exp[j] = B[j] * B_exp_base[j] * mod_factor;
        }

        // Потери (неявная часть) — модификатор применяется к ЦЕЛИ, а не к атакующему
        for (size_t i = 0; i < M_; ++i)
        {
            for (size_t j = 0; j < N_; ++j)
            {
                // === Потери стороны A (тип i) от огня стороны B (тип j) ===
                // Цель — тип i стороны A. Если это дрон — он не получает урон от стандартного огня
                if (!params_.sideA[i].is_uav && !params_.sideA[i].is_fpv)
                {
                    g_vec[i] -= alpha_scaled_ * params_.effectivenessBvsA[j][i] *
                                B_atk[j] * A_exp[i] * (1.0 - params_.sideA[i].defense);
                }

                // === Потери стороны B (тип j) от огня стороны A (тип i) ===
                // Цель — тип j стороны B. Если это дрон — он не получает урон от стандартного огня
                if (!params_.sideB[j].is_uav && !params_.sideB[j].is_fpv)
                {
                    g_vec[M_ + j] -= beta_scaled_ * params_.effectivenessAvsB[i][j] *
                                     A_atk[i] * B_exp[j] * (1.0 - params_.sideB[j].defense);
                }
            }
        }

        // Боевое расходование FPV
        for (size_t i = 0; i < M_; ++i)
        {
            if (params_.sideA[i].is_fpv)
            {
                g_vec[i] -= params_.lambda_use * A[i];
            }
        }
        for (size_t j = 0; j < N_; ++j)
        {
            if (params_.sideB[j].is_fpv)
            {
                g_vec[M_ + j] -= params_.lambda_use * B[j];
            }
        }

        for (size_t i = 0; i < M_; ++i)
        {
            if (params_.sideA[i].is_uav)
            {
                g_vec[i] -= params_.lambda_tech * A[i];
            }
        }
        for (size_t j = 0; j < N_; ++j)
        {
            if (params_.sideB[j].is_uav)
            {
                g_vec[M_ + j] -= params_.lambda_tech * B[j];
            }
        }

        // === НОВОЕ: Вычисление относительных скоростей потерь (ОБЯЗАТЕЛЬНО перед моралью!) ===
        std::vector<double> loss_A(M_, 0.0), loss_B(N_, 0.0);
        for (size_t i = 0; i < M_; ++i)
            // Пропускаем БПЛА и FPV
            if (A[i] > 1e-6 && !params_.sideA[i].is_uav && !params_.sideA[i].is_fpv)
                loss_A[i] = std::max(0.0, -g_vec[i] / A[i]);
            else
                loss_A[i] = 0.0; // Для дронов скорость потерь для морали = 0
        for (size_t j = 0; j < N_; ++j)
            if (B[j] > 1e-6 && !params_.sideB[j].is_uav && !params_.sideB[j].is_fpv)
                loss_B[j] = std::max(0.0, -g_vec[M_ + j] / B[j]);
            else
                loss_B[j] = 0.0;

        // === ИСПРАВЛЕНИЕ: Учитываем только "человеческий состав" для морали ===

        // 1. Вычисляем суммарную численность "людей" у противника
        double A_human_total = 0.0;
        double B_human_total = 0.0;

        for (size_t i = 0; i < M_; ++i)
            if (!params_.sideA[i].is_uav && !params_.sideA[i].is_fpv)
                A_human_total += A[i];

        for (size_t j = 0; j < N_; ++j)
            if (!params_.sideB[j].is_uav && !params_.sideB[j].is_fpv)
                B_human_total += B[j];

        // 2. Вычисляем средневзвешенную скорость потерь (только по людям)
        double r_avg_B = 0.0;
        double r_avg_A = 0.0;

        if (B_human_total > 1e-6)
        {
            for (size_t j = 0; j < N_; ++j)
            {
                // Учитываем вклад только если это "человеческий" тип войск
                if (!params_.sideB[j].is_uav && !params_.sideB[j].is_fpv)
                    r_avg_B += loss_B[j] * B[j];
            }
            r_avg_B /= B_human_total;
        }

        if (A_human_total > 1e-6)
        {
            for (size_t i = 0; i < M_; ++i)
            {
                if (!params_.sideA[i].is_uav && !params_.sideA[i].is_fpv)
                    r_avg_A += loss_A[i] * A[i];
            }
            r_avg_A /= A_human_total;
        }

        // 3. Обновление морали (без изменений — использует уже исправленные r_avg)
        for (size_t i = 0; i < M_; ++i)
        {
            f_vec[M_ + N_ + i] = -params_.sideA[i].morale_decay * A_m[i] - params_.moral_debaffA * loss_A[i] * A_m[i] + params_.epsilon_success * r_avg_B * (1.0 - A_m[i]);
        }
        for (size_t j = 0; j < N_; ++j)
        {
            f_vec[2 * M_ + N_ + j] = -params_.sideB[j].morale_decay * B_m[j] - params_.moral_debaffB * loss_B[j] * B_m[j] + params_.epsilon_success * r_avg_A * (1.0 - B_m[j]);
        }

        // Снабжение (явная часть)
        for (size_t i = 0; i < M_; ++i)
        {
            f_vec[2 * M_ + 2 * N_ + i] = -params_.sideA[i].supply_decay * A_s[i];
        }
        for (size_t j = 0; j < N_; ++j)
        {
            f_vec[3 * M_ + 2 * N_ + j] = -params_.sideB[j].supply_decay * B_s[j];
        }
    }

    std::vector<double> IMEXSolver::explicit_rk2_step(const std::vector<double> &y_n, double dt) const
    {
        std::vector<double> f_n, g_n;
        double U_A_dummy, U_B_dummy;
        rhs_split(y_n, f_n, g_n, U_A_dummy, U_B_dummy);

        std::vector<double> y_temp = y_n;
        for (size_t i = 0; i < state_size_; ++i)
            y_temp[i] = y_n[i] + 0.5 * dt * f_n[i];
        project_to_feasible(y_temp);

        std::vector<double> f_temp, g_temp;
        rhs_split(y_temp, f_temp, g_temp, U_A_dummy, U_B_dummy);

        std::vector<double> y_exp = y_n;
        for (size_t i = 0; i < state_size_; ++i)
            y_exp[i] = y_n[i] + dt * f_temp[i];
        project_to_feasible(y_exp);

        return y_exp;
    }

    std::vector<double> IMEXSolver::implicit_cn_step(const std::vector<double> &y_exp, const std::vector<double> &g_n, double dt, int &fail_count, int &out_newton_iterations) const
    {
        std::vector<double> y_pred = y_exp;
        const int max_iter = params_.max_newton_iter;
        const double tol = params_.tolerance;
        int iter = 0;

        for (; iter < max_iter; ++iter)
        {
            std::vector<double> f_cur, g_cur;
            double U_A_dummy, U_B_dummy;
            rhs_split(y_pred, f_cur, g_cur, U_A_dummy, U_B_dummy);

            std::vector<double> F(state_size_);
            for (size_t i = 0; i < state_size_; ++i)
                F[i] = y_pred[i] - y_exp[i] - 0.5 * dt * (g_n[i] + g_cur[i]);

            double normF = 0.0;
            for (double v : F)
                normF = std::max(normF, std::abs(v));
            if (normF < tol)
                break;

            Matrix J = compute_jacobian_g(y_pred, dt);
            std::vector<double> delta = Matrix::solve_linear_system(J, F);
            for (double &d : delta)
                d = -d;

            double damp = std::min(1.0, 2.0 / (iter + 1.0));
            for (size_t i = 0; i < state_size_; ++i)
                y_pred[i] += damp * delta[i];
            project_to_feasible(y_pred);
        }

        out_newton_iterations = (iter >= max_iter) ? max_iter : iter + 1;
        if (iter >= max_iter)
            ++fail_count;
        return y_pred;
    }

    Matrix IMEXSolver::compute_jacobian_g(const std::vector<double> &y, double dt) const
    {
        auto compute_g = [this](const std::vector<double> &yv) -> std::vector<double>
        {
            std::vector<double> f, g;
            double U_A_dummy, U_B_dummy;
            rhs_split(yv, f, g, U_A_dummy, U_B_dummy);
            return g;
        };
        Matrix Jg = Jacobian::compute_numerical(compute_g, y, 1e-8);
        Matrix J(state_size_, state_size_);
        J.set_identity();
        for (size_t i = 0; i < state_size_; ++i)
            for (size_t j = 0; j < state_size_; ++j)
                J(i, j) -= 0.5 * dt * Jg(i, j);
        return J;
    }

    // === ИСПРАВЛЕННАЯ РЕАЛИЗАЦИЯ compute_metrics ===
    void IMEXSolver::compute_metrics(const std::vector<double> &y,
                                     std::vector<double> &A_atk, std::vector<double> &B_atk,
                                     std::vector<double> &A_exp, std::vector<double> &B_exp,
                                     double &U_A, double &U_B) const
    {
        std::vector<double> A, B, A_m, B_m, A_s, B_s;
        extract_state(y, A, B, A_m, B_m, A_s, B_s);

        U_A = compute_uav_activity(A, A_s, params_.sideA);
        U_B = compute_uav_activity(B, B_s, params_.sideB);
        double uav_adv_B = compute_uav_advantage(U_A, U_B);
        double uav_adv_A = compute_uav_advantage(U_B, U_A);

        std::vector<double> A_cp_eff(M_), B_cp_eff(N_);
        for (size_t i = 0; i < M_; ++i)
            A_cp_eff[i] = params_.sideA[i].combat_power * (1.0 - params_.sideA[i].cp_supply_sensitivity * (1.0 - A_s[i]));
        for (size_t j = 0; j < N_; ++j)
            B_cp_eff[j] = params_.sideB[j].combat_power * (1.0 - params_.sideB[j].cp_supply_sensitivity * (1.0 - B_s[j]));

        A_atk.resize(M_);
        B_atk.resize(N_);
        for (size_t i = 0; i < M_; ++i)
            A_atk[i] = A[i] * A_cp_eff[i] * std::pow(A_m[i], params_.gamma_att);
        for (size_t j = 0; j < N_; ++j)
            B_atk[j] = B[j] * B_cp_eff[j] * std::pow(B_m[j], params_.gamma_att);

        A_exp.resize(M_);
        B_exp.resize(N_);
        for (size_t i = 0; i < M_; ++i)
        {
            double base_exp = params_.epsilon_exp + std::pow(1.0 - A_m[i], params_.gamma_exp);
            double mod_factor = 1.0 + params_.kappa_uav * uav_adv_B;
            A_exp[i] = A[i] * base_exp * mod_factor;
        }
        for (size_t j = 0; j < N_; ++j)
        {
            double base_exp = params_.epsilon_exp + std::pow(1.0 - B_m[j], params_.gamma_exp);
            double mod_factor = 1.0 + params_.kappa_uav * uav_adv_A;
            B_exp[j] = B[j] * base_exp * mod_factor;
        }
    }

    SimulationResults IMEXSolver::solve()
    {
        SimulationResults res;
        auto t0 = std::chrono::high_resolution_clock::now();

        int steps = params_.steps;
        double dt = params_.dt;

        res.time.resize(steps);
        size_t nA = M_, nB = N_;

        res.A_counts.assign(nA, std::vector<double>(steps));
        res.B_counts.assign(nB, std::vector<double>(steps));
        res.A_morale.assign(nA, std::vector<double>(steps));
        res.B_morale.assign(nB, std::vector<double>(steps));
        res.A_supply.assign(nA, std::vector<double>(steps));
        res.B_supply.assign(nB, std::vector<double>(steps));
        res.A_attack.assign(nA, std::vector<double>(steps));
        res.B_attack.assign(nB, std::vector<double>(steps));
        res.A_exposure.assign(nA, std::vector<double>(steps));
        res.B_exposure.assign(nB, std::vector<double>(steps));

        res.UAV_activity_A.resize(steps, 0.0);
        res.UAV_activity_B.resize(steps, 0.0);

        std::vector<double> y = y0_;
        int fail_count = 0;
        int total_newton_iters = 0;
        int newton_call_count = 0;
        int max_newton_iters = 0;

        for (int step = 0; step < steps; ++step)
        {
            res.time[step] = step * dt;

            std::vector<double> A, B, Am, Bm, As, Bs;
            extract_state(y, A, B, Am, Bm, As, Bs);

            for (size_t i = 0; i < nA; ++i)
            {
                res.A_counts[i][step] = A[i];
                res.A_morale[i][step] = Am[i];
                res.A_supply[i][step] = As[i];
            }
            for (size_t j = 0; j < nB; ++j)
            {
                res.B_counts[j][step] = B[j];
                res.B_morale[j][step] = Bm[j];
                res.B_supply[j][step] = Bs[j];
            }

            // === ИСПРАВЛЕННЫЙ ВЫЗОВ compute_metrics ===
            std::vector<double> A_atk, B_atk, A_ex, B_ex;
            double U_A_step, U_B_step;
            compute_metrics(y, A_atk, B_atk, A_ex, B_ex, U_A_step, U_B_step);

            for (size_t i = 0; i < nA; ++i)
            {
                res.A_attack[i][step] = A_atk[i];
                res.A_exposure[i][step] = A_ex[i];
            }
            for (size_t j = 0; j < nB; ++j)
            {
                res.B_attack[j][step] = B_atk[j];
                res.B_exposure[j][step] = B_ex[j];
            }

            // Сохранение активности БПЛА
            res.UAV_activity_A[step] = U_A_step;
            res.UAV_activity_B[step] = U_B_step;

            if (step < steps - 1)
            {
                std::vector<double> f_n, g_n;
                double U_A_dummy, U_B_dummy;
                rhs_split(y, f_n, g_n, U_A_dummy, U_B_dummy);

                std::vector<double> y_exp = explicit_rk2_step(y, dt);
                int newton_iters = 0;
                y = implicit_cn_step(y_exp, g_n, dt, fail_count, newton_iters);

                total_newton_iters += newton_iters;
                ++newton_call_count;
                max_newton_iters = std::max(max_newton_iters, newton_iters);
                ++res.total_iterations;
            }
        }

        res.convergence_failures = fail_count;
        res.avg_newton_iterations = newton_call_count > 0 ? static_cast<double>(total_newton_iters) / newton_call_count : 0.0;
        res.max_newton_iterations = max_newton_iters;

        auto t1 = std::chrono::high_resolution_clock::now();
        res.execution_time_ms = std::chrono::duration<double, std::milli>(t1 - t0).count();

        for (size_t i = 0; i < nA; ++i)
        {
            res.initial_force_A += res.A_counts[i][0];
            res.final_force_A += res.A_counts[i][steps - 1];
        }
        for (size_t j = 0; j < nB; ++j)
        {
            res.initial_force_B += res.B_counts[j][0];
            res.final_force_B += res.B_counts[j][steps - 1];
        }

        if (res.final_force_A > res.final_force_B)
            res.winner = 1;
        else if (res.final_force_B > res.final_force_A)
            res.winner = 2;
        else
            res.winner = 0;

        return res;
    }

} // namespace combat_model