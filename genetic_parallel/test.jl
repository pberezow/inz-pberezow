Genetic = include("geneticPackage.jl")

task_config_path = "zadanie_testowe7x7_237.json"
max_gen = 2000
config = Genetic.loadConfig(task_config_path)
cost_func = Genetic.makeLinear(config.costMatrix)

println("Start test - '$(task_config_path)' - $(max_gen) generations...")

results = []

println("\n\n========================= CALC LINEAR =========================")
for i = 1 : 10
    t1 = time()
    population = Genetic.initPopulation(config, max_gen, cost_func)
    push!(results, population.bestChromosom)
    push!(results, Genetic.findSolution(population))
    t2 = time()
    println("TIME - $i - $(t2-t1) sec")
end

# NTP func A
cost_func_a = Genetic.makeA(2.0, config.costMatrix)

results_a = []

println("\n\n========================= CALC NONLINEAR =========================")
for i = 1 : 10
    t1 = time()
    population = Genetic.initPopulation(config, max_gen, cost_func_a)
    push!(results_a, population.bestChromosom)
    push!(results_a, Genetic.findSolution(population))
    t2 = time()
    println("TIME - $i - $(t2-t1) sec")
end

println("\n\n\n========================= Results =========================")
println("\n========================= LINEAR =========================")
for i = 1 : 2: length(results)
    Genetic.validate(results[i], config.demand, config.supply)
    Genetic.validate(results[i+1], config.demand, config.supply)
    println("$(div(i+1, 2)). First Generation: $(Genetic.getCost(results[i], cost_func))  -->  Last Generation: $(Genetic.getCost(results[i+1], cost_func))")
end

println("\n========================= NONLINEAR =========================")
for i = 1 : 2: length(results_a)
    Genetic.validate(results_a[i], config.demand, config.supply)
    Genetic.validate(results_a[i+1], config.demand, config.supply)
    println("$(div(i+1, 2)). First Generation: $(Genetic.getCost(results_a[i], cost_func_a))  -->  Last Generation: $(Genetic.getCost(results_a[i+1], cost_func_a))")
end