using Base.Threads
# using Distributed
# addprocs(5 - nprocs())

Genetic2 = include("genetic2/geneticPackage.jl")
GeneticParallel = include("genetic_parallel/geneticPackage.jl")
using BenchmarkTools


task_config_path = "genetic_parallel/zadanie_testowe7x7_237.json"
# task_config_path = "testData_100x100.json"
max_gen = 500
config = Genetic2.loadConfig(task_config_path)
config2 = GeneticParallel.loadConfig(task_config_path)

# config.populationSize = 500
# config2.populationSize = 500
# linear
# cost_func = Genetic.makeLinear(config.costMatrix)
# nonlinear
cost_func = Genetic2.makeA(2.0, config.costMatrix)
function genetic2_test(config, max_gen, cost_func)
    population = Genetic2.initPopulation(config, max_gen, cost_func)
    Genetic2.findSolution(population)
end

function genetic_parallel_test(config2, max_gen, cost_func)
    population = GeneticParallel.initPopulation(config2, max_gen, cost_func)
    GeneticParallel.findSolution(population)
end

function run(config, max_gen, cost_func)
    population = Genetic2.initPopulation(config, max_gen, cost_func)
    Genetic2.findSolution(population)
end

function run2(config2, max_gen, cost_func)
    # println(Threads.nthreads())
    population = GeneticParallel.initPopulation(config2, max_gen, cost_func)
    GeneticParallel.findSolution(population)
end

function genetic2_parallel_test(config, max_gen, cost_func)
    # println(nprocs())
    futures = []
    for i = 1 : Threads.nthreads()
        fut = Threads.@spawn run(config, max_gen, cost_func)
        push!(futures, fut)
    end
    res = []
    for i = 1 : length(futures)
        push!(res, fetch(futures[i]))
    end
    res
end

function genetic_parallel2_test(config2, max_gen, cost_func)
    # println(nprocs())
    futures = []
    for i = 1 : Threads.nthreads()
        fut = Threads.@spawn run2(config2, max_gen, cost_func)
        push!(futures, fut)
    end
    res = []
    for i = 1 : length(futures)
        push!(res, fetch(futures[i]))
    end
    res
end

# println("--------------- Genetic2 ---------------")
# @benchmark genetic2_test(config, max_gen, cost_func)

# println("\n\n--------------- GeneticParallel ---------------")
# @benchmark genetic_parallel_test(config2, max_gen, cost_func)