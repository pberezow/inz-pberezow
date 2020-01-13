include("./src/GeneticNTP.jl")
import .GeneticNTP

# w celu uruchomienia podajemy:
# 1 arg: ścieżka do pliku konfiguracyjnego
# 2 arg: nazwa funkcji z pliku functions.jl dostępne - ["Linear", "A", "B", "C", "D", "E", "F", "SetupCost"]
# 3 arg: plik wyjściowy
# 4 arg(opcjonalnie): jeśli wybrano funkcję SetupCost to podajemy ścieżkę do pliku z macierzą kosztów początkowych

if length(ARGS) < 3
    error("Wrong arguments!")
end

input_file = ARGS[1]
func_name = ARGS[2]
output_file = ARGS[3]
setup_cost_file = ""

if func_name == "SetupCost" 
    if length(ARGS) >= 4
        setup_cost_file = ARGS[4]
    else
        error("Wrong arguments!")
    end
end

config = GeneticNTP.loadConfig(input_file)

GeneticNTP.generateGAMSInput(config, output_file, func_name, setup_cost_file)
