include("./src/GeneticNTP.jl")
import .GeneticNTP

# ustawiamy ścieżkę do pliku konfiguracyjnego
const configFile = "./examples/ex_7x7.json"

# ustawiamy ilość iteracji algorytmu
const maxGeneration = 10000

# ustawiamy nazwę funkcji kosztu (definicje dostępnych funkcji znajdują się w katalogu src, w pliku functions.jl)
const costFuncName = "A"

# w przypadku ustawienia przebiegu testowego zostanie narysowany wykres prezentujący ewolucje kosztu najlepszego osobnika na przestrzeni pokoleń
const isTestRun = false

# ścieżka do pliku z macierzą kosztów stałych (do funkcji SetupCost)
const setupCostFile = "./examples/sc_7x7.json"

println("Path: ", configFile)
println("Running on ", Threads.nthreads(), " threads")

# uruchamiamy algorytm dla opisanych wyżej parametrów
result = GeneticNTP.runEA(configFile, maxGeneration, costFuncName, isTestRun, setupCostFile)

println("Best result: ", result.cost)

# aby uruchomic program na większej ilości wątków należy przd wywołaniem ustawić wartość zmiennej JULIA_NUM_THREADS=ilość_wątków, czyli np.
# JULIA_NUM_THREADS=4 julia ./run_example.jl
# dla 4 wątków