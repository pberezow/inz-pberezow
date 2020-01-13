include("../src/GeneticNTP.jl")
using .GeneticNTP
using Test

function testSaveLoad()
    demand = [1.0, 10.0]
    supply = [1.0, 5.0, 5.0]
    costMatrix = [1.0 2.0 3.0; 10.0 20.0 30.0]
    mutationProb = 0.1
    mutationRate = 0.05
    crossoverProb = 0.2
    populationSize = 100
    eliteProc = 0.3
    mode = REGULAR_MODE
    numberOfSeparateGenerations = 100

    config = Config(mutationProb,
                    mutationRate, 
                    crossoverProb, 
                    populationSize,
                    eliteProc,
                    costMatrix,
                    demand,
                    supply,
                    mode,
                    numberOfSeparateGenerations,
                    false)
    validate!(config)
    saveConfig(config, "test_config.json")
    
    config2 = loadConfig("test_config.json")
    validate!(config2)

    if config.mutationProb != config2.mutationProb
        return false
    end
    if config.mutationRate != config2.mutationRate
        return false
    end
    if config.crossoverProb != config2.crossoverProb
        return false
    end
    if config.populationSize != config2.populationSize
        return false
    end
    if config.eliteProc != config2.eliteProc
        return false
    end
    if config.costMatrix != config2.costMatrix
        return false
    end
    if config.demand != config2.demand
        return false
    end
    if config.supply != config2.supply
        return false
    end
    if config.mode != config2.mode
        return false
    end
    if config.numberOfSeparateGenerations != config2.numberOfSeparateGenerations
        return false
    end

    return true
end

function testChromosom()
    config = loadConfig("test_config.json")
    costFunc = getFunctions(config.costMatrix)["Linear"]

    chromosom = init(config.demand, config.supply)
    @test validate(chromosom, config.demand, config.supply) == true
    @test size(chromosom.result) == (2,3)

    chromosom_cp = copy(chromosom)
    mutate!(chromosom_cp, config.demand, config.supply, 2, 2)
    @test chromosom_cp.isCalculated == false
    @test chromosom_cp.result !== chromosom.result
    
    mutate2!(chromosom_cp, config.demand, config.supply, 2, 2)
    mutate!(chromosom, config.demand, config.supply, 2, 2)
    @test validate(chromosom_cp, config.demand, config.supply)
    @test validate(chromosom, config.demand, config.supply)

    eval!(chromosom_cp, costFunc)
    eval!(chromosom, costFunc)
    @test chromosom_cp.isCalculated == true
    if chromosom.result != chromosom_cp.result
        @test chromosom.cost != chromosom_cp.cost
    else
        @test chromosom.cost == chromosom_cp.cost
    end

    cross!(chromosom, chromosom_cp)
    @test validate(chromosom, config.demand, config.supply)
    @test validate(chromosom_cp, config.demand, config.supply)

    @test getSizeForMutation(chromosom, 0.1) == (2, 2)

end

function testPopulation()
    config = loadConfig("test_config.json")
    costFunc = getFunctions(config.costMatrix)["Linear"]

    population = initPopulation(config, 100, costFunc)
    @test population.currGeneration == 1
    @test length(population.chromosomSet) == 100
    
    nextGeneration!(population, population.partialPopulationsData[1][3], population.partialPopulationsData[1][4])
    @test population.currGeneration == 2
    
    c = findSolution(population)
    @test population.currGeneration == 100
    @test typeof(c) == Chromosom
    findSolution(population)
    @test population.currGeneration == 100
end


println("Testing config.jl...")
@test testSaveLoad()
println("OK.")

println("Testing chromosom.jl...")
testChromosom()
println("OK.")

println("Testing population.jl...")
testPopulation()
println("OK.")