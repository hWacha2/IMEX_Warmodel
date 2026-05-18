#pragma once
#include <vector>
#include <cmath>
#include <functional>

namespace combat_model {

class Matrix {
public:
    size_t rows;
    size_t cols;
    std::vector<double> data;
    
    Matrix() : rows(0), cols(0) {}
    Matrix(size_t r, size_t c) : rows(r), cols(c), data(r * c, 0.0) {}
    
    double& operator()(size_t i, size_t j) { return data[i * cols + j]; }
    double operator()(size_t i, size_t j) const { return data[i * cols + j]; }
    
    void resize(size_t r, size_t c) {
        rows = r;
        cols = c;
        data.assign(r * c, 0.0);
    }
    
    void set_identity();
    
    static std::vector<double> solve_linear_system(Matrix A, std::vector<double> b);
};

class Jacobian {
public:
    static Matrix compute_numerical(
        const std::function<std::vector<double>(const std::vector<double>&)>& func,
        const std::vector<double>& y,
        double eps = 1e-8
    );
};

} // namespace combat_model