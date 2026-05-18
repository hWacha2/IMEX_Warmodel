#include "matrix.h"
#include <algorithm>
#include <stdexcept>

namespace combat_model {

void Matrix::set_identity() {
    for (size_t i = 0; i < std::min(rows, cols); ++i) {
        (*this)(i, i) = 1.0;
    }
}

std::vector<double> Matrix::solve_linear_system(Matrix A, std::vector<double> b) {
    size_t n = A.rows;
    if (A.cols != n || b.size() != n) {
        throw std::invalid_argument("Invalid system dimensions");
    }
    
    for (size_t k = 0; k < n; ++k) {
        size_t max_row = k;
        double max_val = std::abs(A(k, k));
        for (size_t i = k + 1; i < n; ++i) {
            if (std::abs(A(i, k)) > max_val) {
                max_val = std::abs(A(i, k));
                max_row = i;
            }
        }
        
        if (max_row != k) {
            for (size_t j = 0; j < n; ++j) {
                std::swap(A(k, j), A(max_row, j));
            }
            std::swap(b[k], b[max_row]);
        }
        
        if (std::abs(A(k, k)) < 1e-12) {
            continue;
        }
        
        for (size_t i = k + 1; i < n; ++i) {
            double factor = A(i, k) / A(k, k);
            for (size_t j = k; j < n; ++j) {
                A(i, j) -= factor * A(k, j);
            }
            b[i] -= factor * b[k];
        }
    }
    
    std::vector<double> x(n, 0.0);
    for (int i = static_cast<int>(n) - 1; i >= 0; --i) {
        if (std::abs(A(i, i)) < 1e-12) {
            x[i] = 0.0;
            continue;
        }
        double sum = b[i];
        for (size_t j = i + 1; j < n; ++j) {
            sum -= A(i, j) * x[j];
        }
        x[i] = sum / A(i, i);
    }
    
    return x;
}

Matrix Jacobian::compute_numerical(
    const std::function<std::vector<double>(const std::vector<double>&)>& func,
    const std::vector<double>& y,
    double eps
) {
    size_t n = y.size();
    Matrix J(n, n);
    
    for (size_t j = 0; j < n; ++j) {
        std::vector<double> y_plus = y;
        std::vector<double> y_minus = y;
        
        double h = eps * std::max(1.0, std::abs(y[j]));
        y_plus[j] += h;
        y_minus[j] -= h;
        
        std::vector<double> f_plus = func(y_plus);
        std::vector<double> f_minus = func(y_minus);
        
        for (size_t i = 0; i < n; ++i) {
            J(i, j) = (f_plus[i] - f_minus[i]) / (2.0 * h);
        }
    }
    
    return J;
}

} // namespace combat_model