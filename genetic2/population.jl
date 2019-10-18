"""
File contains Population struct, which represents population of chromosoms.
Functions:
    initPopulation(config::Config, maxGeneration::Int)
    initPopulation(configFile::String, maxGeneration::Int)
    nextGeneration!(self::Population)
"""

# using Random

mutable struct Population
    config::Config
    currGeneration::Int
    maxGeneration::Int
    chromosomSet::Vector{Chromosom}
    bestChromosom::Chromosom
    configFile::String
    costFunction::Function
end

function initPopulation(config::Config, maxGeneration::Int, costFunction::Function)
    validate!(config)
    # costFunction = makeLinear(config.costMatrix)

    chromosomSet = Vector{Chromosom}()
    bestIdx = 1
    for i = 1 : config.populationSize
        c = init(config.demand, config.supply)
        eval!(c, costFunction)
        push!(chromosomSet, c)
        if getCost(c, costFunction) < getCost(chromosomSet[bestIdx], costFunction)
            bestIdx = i
        end
    end
    bestChromosom = copy(chromosomSet[bestIdx])

    return Population(config, 1, maxGeneration, chromosomSet, bestChromosom, "", costFunction)
end

function initPopulation(configFile::String, maxGeneration::Int, costFunction::Function)
    config = loadConfig(configFile)
    return initPopulation(config, maxGeneration, costFunction)
end

function nextGeneration!(self::Population)
    # for statistic purpose
    mutations = 0
    crossovers = 0

    for i = 1 : self.config.populationSize
        if rand() <= self.config.mutationProb
            afterMutation = mutate(self.chromosomSet[i], self.config.demand, self.config.supply)
            push!(self.chromosomSet, afterMutation)
            mutations += 1
        end
    end

    for i = 1 : self.config.populationSize
        if rand() <= self.config.crossoverProb
            other = i
            while other == i
                other = rand(1:self.config.populationSize)
            end
            afterCross1, afterCross2 = cross(self.chromosomSet[i], self.chromosomSet[other])
            push!(self.chromosomSet, afterCross1, afterCross2)
            crossovers += 1
        end
    end

    for c in self.chromosomSet
        eval!(c, self.costFunction)
    end
    sort!(self.chromosomSet)
    self.bestChromosom = copy(self.chromosomSet[1])
    self.chromosomSet = self.chromosomSet[1:self.config.populationSize]
    # for i = 1:self.config.populationSize
    #     eval!(self.chromosomSet[i], self.costFunction)
    #     if self.chromosomSet[i].cost < self.bestChromosom.cost
    #         # possible need of deep copy
    #         self.bestChromosom = self.chromosomSet[i]
    #     end
    # end

    # deep copy of best chromosm
    # self.bestChromosom = copy(self.bestChromosom) # Chromosom(copy(population.bestChromosom.resultMatrix), population.bestChromosom.cost)

    self.currGeneration += 1

    println("Generation: $(self.currGeneration)   Mutations: $(mutations) Crossovers: $(crossovers)   Best Solution: $(self.bestChromosom.cost)")
end

function findSolution(population::Population)
    while population.currGeneration < population.maxGeneration
        nextGeneration!(population)
    end

    return population.bestChromosom
end

function findSolution(config::Config, maxGenerations::Int, costFunction=false)
    if costFunction
        error("costFunction - not implemented yet.")
    end

    population = initPopulation(config, maxGenerations)

    return findSolution(population)
end