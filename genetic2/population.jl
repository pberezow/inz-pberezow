"""
File contains Population struct, which represents population of chromosoms.
Functions:
    - initPopulation(config::Config, maxGeneration::Int, costFunction::Function)
    - selection(self::Population)
    - nextGeneration!(self::Population)
    - findSolution(population::Population)
"""


"""
    Structure used to represent population of Chromosoms.
"""
mutable struct Population
    config::Config
    currGeneration::Int
    maxGeneration::Int
    chromosomSet::Vector{Chromosom}
    bestChromosom::Chromosom
    configFile::String
    costFunction::Function
    # to plot results
    bestsVector::Vector{Float64}
end

"""
    initPopulation(config, maxGeneration, costFunction)

Initializes new population.

# Arguments
- `config::Config`: Config struct including all population's parameters.
- `maxGeneration::Integer`: number of iterations before algorithm stops.
- `costFunction::Function`: function used to calculate cost of single solution, should have signature func(resultMatrix::Array{Float64, 2}).
"""
function initPopulation(config::Config, maxGeneration::Int, costFunction::Function)
    validate!(config)

    chromosomSet = Vector{Chromosom}()
    for i = 1 : config.populationSize
        c = init(config.demand, config.supply)
        eval!(c, costFunction)
        push!(chromosomSet, c)
    end

    sort!(chromosomSet)
    bestChromosom = copy(chromosomSet[1])

    # to draw plots
    vec = Vector{Float64}()
    push!(vec, getCost(bestChromosom, costFunction))

    return Population(config, 1, maxGeneration, chromosomSet, bestChromosom, "", costFunction, vec)
end

"""
    Select chromosoms to reproduction.
"""
function selection(self::Population)
    #1
    fittnessSum = 0.0
    fittness = []
    for i = 1 : length(self.chromosomSet)
        f = getCost(self.chromosomSet[i], self.costFunction)
        push!(fittness, f)
        fittnessSum += f
    end

    #2
    fittness[1] = fittness[1] / fittnessSum
    for i = 2 : length(fittness)
        fittness[i] = fittness[i] / fittnessSum + fittness[i-1]
    end

    #3
    parents = []
    parentsToPick = floor(Int, self.config.populationSize * self.config.crossoverProb)
    if parentsToPick % 2 == 1
        parentsToPick += 1
    end
    # println(fittness)
    for i = 1 : parentsToPick
        # add binarySearch
        pick = rand()
        # println(pick)
        idx = findlast(x -> x <= pick, fittness)
        if idx === nothing
            idx = 1
        end
        push!(parents, copy(self.chromosomSet[idx]))
    end

    return parents
end

"""
    nextGeneration!(self)

Performs single iteration of genetic algorithm.

# Arguments
- `self::Population`: evolving population.
"""
function nextGeneration!(self::Population)
    # for testing purposes
    mutations = 0
    crossovers = 0

    parents = selection(self)
    
    # crossovers on parents
    newChromosomeSet = []
    for i = 1 : 2 : length(parents)
        c1, c2 = cross(parents[i], parents[i+1])
        push!(newChromosomeSet, c1)
        push!(newChromosomeSet, c2)
        crossovers += 1
    end

    # copy eliteProc
    eliteCount = floor(Int, self.config.populationSize * self.config.eliteProc)
    for i = 1 : eliteCount
        push!(newChromosomeSet, copy(self.chromosomSet[i]))
    end

    # add extra random chromosoms from prev generation
    for i = length(newChromosomeSet) + 1 : self.config.populationSize
        idx = rand(eliteCount+1 : self.config.populationSize)
        push!(newChromosomeSet, copy(self.chromosomSet[idx]))
    end

    # mutations
    for i = 1 : self.config.populationSize
        if rand() <= self.config.mutationProb
            mutate!(newChromosomeSet[i], self.config.demand, self.config.supply)
            mutations += 1
        end
    end

    for c in newChromosomeSet
        eval!(c, self.costFunction)
    end
    sort!(newChromosomeSet)
    self.chromosomSet = newChromosomeSet
    # swap only if better than current best?
    if getCost(self.bestChromosom, self.costFunction) > getCost(self.chromosomSet[1], self.costFunction)
        self.bestChromosom = copy(self.chromosomSet[1])
    end

    self.currGeneration += 1
    
    push!(self.bestsVector, getCost(self.bestChromosom, self.costFunction))

    # println("Generation: $(self.currGeneration)   Mutations: $(mutations) Crossovers: $(crossovers)   Best Solution: $(self.bestChromosom.cost)    Population Size: $(length(newChromosomeSet))")
end

function __nextGeneration!(self::Population)
    # NOT USED ANYMORE
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

    self.currGeneration += 1

    println("Generation: $(self.currGeneration)   Mutations: $(mutations) Crossovers: $(crossovers)   Best Solution: $(self.bestChromosom.cost)")
end

"""
    Run's genetic algorithm on population.
"""
function findSolution(population::Population)
    while population.currGeneration < population.maxGeneration
        nextGeneration!(population)
    end

    return population.bestChromosom
end

function drawResults(self::Population, filename::String, runNumber::Int=-1)
    if self.currGeneration != self.maxGeneration
        println("You have to evolve population first!")
        return false
    end

    title = "mutProb: $(self.config.mutationProb), crossProb: $(self.config.crossoverProb), elite: $(self.config.eliteProc), popSize: $(self.config.populationSize), maxGen: $(self.maxGeneration)"
    if runNumber > 0
        title = "($runNumber)  " * title
    end
    xlabel = "Generation"
    ylabel = "Best cost"
    plt = plot(1:self.maxGeneration, self.bestsVector, title=title, xlabel=xlabel, ylabel=ylabel, show=false)
    savefig(plt, filename)

    return true
end