Genetic2 = include("genetic2/geneticPackage.jl")
GeneticParallel = include("genetic_parallel/geneticPackage.jl")
using BenchmarkTools

task_config_path = "genetic_parallel/zadanie_testowe7x7_237.json"
max_gen = 1000
config = Genetic2.loadConfig(task_config_path)
config2 = GeneticParallel.loadConfig(task_config_path)

config.populationSize = 500
config2.populationSize = 500
# linear
# cost_func = Genetic.makeLinear(config.costMatrix)
# nonlinear
cost_func = Genetic2.makeA(2.0, config.costMatrix)

println("--------------- Genetic2 ---------------")
@btime begin
    population = Genetic2.initPopulation(config, max_gen, cost_func)
    Genetic2.findSolution(population)
end

println("\n\n--------------- GeneticParallel ---------------")
@btime begin
    population = GeneticParallel.initPopulation(config2, max_gen, cost_func)
    GeneticParallel.findSolution(population)
end