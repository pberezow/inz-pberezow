include("geneticPackage.jl")

function findParams(configFile::String, costFuncName::String, outFile::String, setupCostFile::String="")
    # parameters
    maxGen = [1000, 10000, 20000]
    popSize = [100, 400]
    crossProb = [0.2, 0.5, 0.7]
    mutProb = [0.05, 0.1, 0.2]
    mutRate = [0.03, 0.05, 0.1]
    elite = [0.3, 0.1, 0.0]
    mode = [GeneticNTP.REGULAR_MODE]
    separateGen = [1]

    tries = 5
    config = GeneticNTP.loadConfig(configFile)

    functionsDict = GeneticNTP.getFunctions(config.costMatrix, setupCostFile)
    costFunc = functionsDict[costFuncName]

    # csv with structure:
    # popSize, mode, separateGen, elite, crossProb, mutProb, mutRate, maxGen, time, nTry, result 
    open(outFile, "w") do f
        write(f, "===============INFO===============\n=file=configFile\n=popSize, mode, separateGen, elite, crossProb, mutProb, mutRate, maxGen, time, nTry, result\n\n\n")

        for pS in popSize
            for md in mode
                for sG in separateGen
                    for el in elite
                        for cP in crossProb
                            for mP in mutProb
                                for mR in mutRate
                                    # set config
                                    config.populationSize = pS
                                    config.mode = md
                                    config.numberOfSeparateGenerations = sG
                                    config.eliteProc = el
                                    config.crossoverProb = cP
                                    config.mutationProb = mP
                                    config.mutationRate = mR
                                    config.validated = false

                                    for mG in maxGen

                                        for nt = 1 : tries
                                            result = -1.0
                                            
                                            t1 = time()
                                            if config.mode == GeneticNTP.REGULAR_MODE
                                                population = GeneticNTP.initPopulation(config, mG, costFunc, false, 1)
                                                result = GeneticNTP.findSolution(population).cost
                                                
                                            elseif config.mode == GeneticNTP.ISLAND_MODE
                                                population = GeneticNTP.initPopulation(config, mG, costFunc, false, Threads.nthreads())
                                                result = GeneticNTP.findSolution(population).cost
                                            
                                            end
                                            t2 = time()

                                            write(f, "$pS;$md;$sG;$el;$cP;$mP;$mR;$mG;$(t2-t1);$nt;$result\n")

                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    nothing
end


const conf = ARGS[1]
const funcName = ARGS[2]
const outFile = ARGS[3]

findParams(conf, funcName, outFile)