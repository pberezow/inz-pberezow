Genetic = include("geneticPackage.jl")

task_config_path = "zadanie_testowe7x7_237.json"
config = Genetic.loadConfig(task_config_path)
costFunc = Genetic.makeA(2.0, config.costMatrix)

# params
popSize = 100 : 100 : 500
maxGen = 100 : 100 : 2000
crossProb = 0.4 : 0.1 : 0.8
mutProb = 0.01 : 0.03 : 0.15
elite = 0.05 : 0.05 : 0.2

# popSize = 100 : 50 : 150
# maxGen = 100 : 100 : 200
# crossProb = 0.2 : 0.1 : 0.3
# mutProb = 0.01 : 0.03 : 0.04
# elite = 0.05 : 0.05 : 0.1

runs = 1:10

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
                        filename = "r_$(run)___res_$(population.bestChromosom.cost)"
                        Genetic.drawResults(population, filename, run)
                    end
                    cd("..")
                end
            end
        end
    end
end