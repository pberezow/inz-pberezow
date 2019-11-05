Genetic = include("geneticPackage.jl")

task_config_path = "zadanie_testowe7x7_237.json"
max_gen = 2000
config = Genetic.loadConfig(task_config_path)
# linear
# cost_func = Genetic.makeLinear(config.costMatrix)
# nonlinear
cost_func = Genetic.makeA(2.0, config.costMatrix)


@time population = Genetic.initPopulation(config, max_gen, cost_func)
firstBest = copy(population.bestChromosom)
@time Genetic.findSolution(population)
lastBest = copy(population.bestChromosom)

println("Result:")
println("Start test - single run - '$(task_config_path)'")
println("Crossover Probability: $(config.crossoverProb)")
println("Mutation Probability: $(config.mutationProb)")
println("Population Size: $(config.populationSize)")
println("Max Generation: $(max_gen)")
println("First Generation: $(Genetic.getCost(firstBest, cost_func))  -->  Last Generation: $(Genetic.getCost(lastBest, cost_func))")
