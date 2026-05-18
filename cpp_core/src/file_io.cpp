#include "file_io.h"
#include <fstream>
#include <iostream>

namespace combat_model {

bool FileIO::export_results_to_csv(
    const SimulationResults& results,
    const std::string& filepath,
    const std::vector<std::string>& unit_names_a,
    const std::vector<std::string>& unit_names_b) {
    
    std::ofstream file(filepath);
    if (!file.is_open()) {
        std::cerr << "Failed to open file: " << filepath << std::endl;
        return false;
    }
    
    // Заголовки столбцов
    file << "Time";
    
    // Заголовки для стороны A
    for (const auto& name : unit_names_a) {
        file << ",A_" << name << "_count"
             << ",A_" << name << "_morale"
             << ",A_" << name << "_supply"
             << ",A_" << name << "_attack"
             << ",A_" << name << "_exposure";
    }
    
    // Заголовки для стороны B
    for (const auto& name : unit_names_b) {
        file << ",B_" << name << "_count"
             << ",B_" << name << "_morale"
             << ",B_" << name << "_supply"
             << ",B_" << name << "_attack"
             << ",B_" << name << "_exposure";
    }
    file << "\n";
    
    // Запись данных по шагам времени
    size_t nTimes = results.time.size();
    size_t nA = results.A_counts.size();
    size_t nB = results.B_counts.size();
    
    for (size_t t = 0; t < nTimes; ++t) {
        file << results.time[t];
        
        // Данные стороны A
        for (size_t i = 0; i < nA; ++i) {
            file << "," << results.A_counts[i][t]
                 << "," << results.A_morale[i][t]
                 << "," << results.A_supply[i][t]
                 << "," << results.A_attack[i][t]
                 << "," << results.A_exposure[i][t];
        }
        
        // Данные стороны B
        for (size_t j = 0; j < nB; ++j) {
            file << "," << results.B_counts[j][t]
                 << "," << results.B_morale[j][t]
                 << "," << results.B_supply[j][t]
                 << "," << results.B_attack[j][t]
                 << "," << results.B_exposure[j][t];
        }
        file << "\n";
    }
    
    file.close();
    return true;
}

} // namespace combat_model