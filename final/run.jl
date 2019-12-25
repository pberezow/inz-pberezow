include("./src/GeneticNTP.jl")
import .GeneticNTP

# w celu uruchomienia podajemy:
# 1 arg: ścieżka do pliku konfiguracyjnego
# 2 arg: ilość pokoleń algorytmu
# 3 arg: nazwa funkcji celu ich definicje znajduja się w pliku src/functions.jl
# 4 arg(dodatkowy): jeśli "true", to zostanie narysowany wykres ewolucji najlepszego osobnika
# 5 arg(dodatkowy): w przypadku wyboru funkcji celu "SetupCost" najeży podać tu ścieżkę do pliku z macierzą kosztów stałych

if length(ARGS) < 3 || length(ARGS) > 5
    error("Wrong arguments!")
end

const configFile = ARGS[1]

const maxGeneration = tryparse(Int, ARGS[2])
if isnothing(maxGeneration)
    error("Wrong value of 2nd (maxGeneration) argument!")
end

const costFuncName = ARGS[3]

_isTestRun = false
if length(ARGS) > 3 && ARGS[4] == "true"
    _isTestRun = true
end
const isTestRun = _isTestRun

_setupCostFile = ""
if length(ARGS) > 4
    _setupCostFile = ARGS[5]
end
const setupCostFile = _setupCostFile

println("Path: ", configFile)

println("Running on ", Threads.nthreads(), " threads")

function run(precompile::Bool=false)
    t1 = time()
    if precompile
        result = GeneticNTP.runEA(configFile, 2, costFuncName, false, setupCostFile)
    else
        result = GeneticNTP.runEA(configFile, maxGeneration, costFuncName, isTestRun, setupCostFile)
    end
    t2 = time()

    println("Done in: ", t2-t1)

    println("Best result: ", result.cost)
    return nothing
end

# run(true)
# println("\n\n")
@time run()