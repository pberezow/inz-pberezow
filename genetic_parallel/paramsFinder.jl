Genetic = include("geneticPackage.jl")

task_config_path = "zadanie_testowe7x7_237.json"
config = Genetic.loadConfig(task_config_path)
costFunc = Genetic.makeA(2.0, config.costMatrix)

# params
popSize = 100 : 100 : 500
maxGen = 100 : 200 : 2100
crossProb = 0.5 : 0.1 : 0.8
mutProb = 0.01 : 0.02 : 0.11
elite = 0.05 : 0.05 : 0.2

# popSize = 100 : 50 : 150
# maxGen = 100 : 100 : 200
# crossProb = 0.2 : 0.1 : 0.3
# mutProb = 0.01 : 0.03 : 0.04
# elite = 0.05 : 0.05 : 0.1

runs = 1:10

allTests = length(popSize) * length(maxGen) * length(crossProb) * length(mutProb) * length(elite) * length(runs)
doneRuns = 0

best_results = Vector{Tuple{Float64, String}}()

if !isdir("results")
    mkdir("results")
end
cd("results")

for pS in popSize
    for mG in maxGen
        for cP in crossProb
            for mP in mutProb
                for e in elite
                    config.populationSize = pS
                    config.mutationProb = mP
                    config.crossoverProb = cP
                    config.eliteProc = e

                    path = "pS_$(pS)__mG_$(mG)__cP_$(cP)__mP_$(mP)__e_$(e)/"
                    if !isdir(path)
                        mkdir(path)
                    end
                    cd(path)

                    for run in runs
                        population = Genetic.initPopulation(config, mG, costFunc)
                        Genetic.findSolution(population)
                        filename = "r_$(run)___res_$(population.bestChromosom.cost).png"
                        Genetic.drawResults(population, filename, run)

                        push!(best_results, (Genetic.getCost(population.bestChromosom, population.costFunction), path))
                    end
                    
                    cd("..")
                    global doneRuns += length(runs)
                    println("Runs Done: $(doneRuns) / $(allTests)    ($(doneRuns/allTests))")
                end

                sort!(best_results)
                global best_results = best_results[1:40]
            end
        end
    end
end

println(best_results)
println("\n\n")

for run in best_results
    println(run)
end