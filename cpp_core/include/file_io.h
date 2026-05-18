#pragma once
#include "types.h"
#include <string>
#include <vector>

namespace combat_model {

class FileIO {
public:
    static bool save_params_to_json(const CombatParams& params, const std::string& filepath);
    static bool save_results_to_json(const SimulationResults& results, const std::string& filepath);
    static bool export_results_to_csv(const SimulationResults& results,
                                      const std::string& filepath,
                                      const std::vector<std::string>& unit_names_a,
                                      const std::vector<std::string>& unit_names_b);
    
private:
    static std::string escape_json_string(const std::string& str);
    static std::string double_to_string(double val, int precision = 6);
};

} // namespace combat_model