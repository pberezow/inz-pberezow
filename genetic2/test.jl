Genetic = include("geneticPackage.jl")

task_config_path = "zadanie_testowe7x7_237.json"
max_gen = 1000
config = Genetic.loadConfig(task_config_path)
cost_func = Genetic.makeLinear(config.costMatrix)

results = []

for i = 1 : 10
    t1 = time()
    population = Genetic.initPopulation(config, max_gen, cost_func)
    push!(results, population.bestChromosom)
    push!(results, Genetic.findSolution(population))
    t2 = time()
    println("TIME - $i - $(t2-t1) sec.")
end

println("\n\n\n=============== Results ===============")
for i = 1 : 2: length(results)
    Genetic.validate(results[i], config.demand, config.supply)
    Genetic.validate(results[i+1], config.demand, config.supply)
    println("$(div(i+1, 2)). First Generation: $(Genetic.getCost(results[i], cost_func))                Last Generation: $(Genetic.getCost(results[i+1], cost_func))")
end