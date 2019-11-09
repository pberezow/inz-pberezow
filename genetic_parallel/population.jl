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
    bestsVector::Vector{Float64} # to plot results
    isTestRun::Bool
    mutex::ReentrantLock
end

"""
    initPopulation(config, maxGeneration, costFunction)

Initializes new population.

# Arguments
- `config::Config`: Config struct including all population's parameters.
- `maxGeneration::Integer`: number of iterations before algorithm stops.
- `costFunction::Function`: function used to calculate cost of single solution, should have signature func(resultMatrix::Array{Float64, 2}).
"""
function initPopulation(config::Config, maxGeneration::Int, costFunction::Function, isTestRun::Bool=false)
    validate!(config)

    chromosomSet = Vector{Chromosom}()
    mutex = ReentrantLock()
    Threads.@threads for i = 1 : config.populationSize
        c = init(config.demand, config.supply)
        eval!(c, costFunction)
        lock(mutex)
        push!(chromosomSet, c)
        unlock(mutex)
        # println("Done - chromosom $i -- Thread: $(Threads.threadid())")
        # chromosomSet[i] = c
    end

    # TODO: swap to multi threaded merge sort
    sort!(chromosomSet)
    bestChromosom = copy(chromosomSet[1])

    # to draw plots
    vec = Vector{Float64}()
    if isTestRun
        push!(vec, getCost(bestChromosom, costFunction))
    end

    return Population(config, 1, maxGeneration, chromosomSet, bestChromosom, "", costFunction, vec, isTestRun, mutex)
end

"""
    Select chromosoms to reproduction.
"""
function selection(self::Population)
    #1
    fittness = Vector{Float64}(undef, length(self.chromosomSet))
    
    fittness[length(self.chromosomSet)] = getCost(self.chromosomSet[length(self.chromosomSet)], self.costFunction)
    for i = length(self.chromosomSet)-1 : -1 : 1
        fittness[i] = getCost(self.chromosomSet[i], self.costFunction) + fittness[i+1]
    end

    #2
    fittness ./= fittness[1]

    #3
    parentsToPick = floor(Int, self.config.populationSize * self.config.crossoverProb)
    if parentsToPick % 2 == 1
        parentsToPick += 1
    end
    parents = Vector{Chromosom}(undef, parentsToPick)

    # println(fittness)
    for i = 1 : parentsToPick
        # add binarySearch
        pick = rand()
        # println(pick)
        idx = findlast(x -> x <= pick, fittness)
        if idx === nothing
            idx = 1
        end
        parents[i] = copy(self.chromosomSet[idx])
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
    # DONE

    parents = selection(self)
    
    # crossovers on parents
    newChromosomeSet = Vector{Chromosom}(undef, length(self.chromosomSet))
    Threads.@threads for i = 1 : 2 : length(parents)
        cross!(parents[i], parents[i+1])
        newChromosomeSet[i] = parents[i]
        newChromosomeSet[i+1] = parents[i+1]
    end
    lastIdx = length(parents)

    # copy eliteProc
    eliteCount = floor(Int, self.config.populationSize * self.config.eliteProc)
    for i = 1 : eliteCount
        newChromosomeSet[lastIdx+=1] = self.chromosomSet[i]
    end
    lastIdx += 1

    # add extra random chromosoms from prev generation
    for i = lastIdx : self.config.populationSize
        selected_idx = rand(eliteCount+1 : self.config.populationSize)
        # .= instead of copy()
        newChromosomeSet[i] = copy(self.chromosomSet[selected_idx])
    end

    # mutations + evaluation
    Threads.@threads for c in newChromosomeSet
        if rand() <= self.config.mutationProb
            mutate!(c, self.config.demand, self.config.supply)
        end
        eval!(c, self.costFunction)
    end

    # TODO: swap to merge sort
    sort!(newChromosomeSet)
    self.chromosomSet = newChromosomeSet
    # swap only if better than current best?
    if getCost(self.bestChromosom, self.costFunction) > getCost(self.chromosomSet[1], self.costFunction)
        self.bestChromosom = copy(self.chromosomSet[1])
    end

    self.currGeneration += 1
    return nothing
end

function nextGenerationTest!(self::Population)
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

"""
    Run's genetic algorithm on population.
"""
function findSolution(population::Population)
    if population.isTestRun
        while population.currGeneration < population.maxGeneration
            nextGenerationTest!(population)
        end
    else
        while population.currGeneration < population.maxGeneration
            nextGeneration!(population)
        end
    end

    return population.bestChromosom
end

function drawResults(self::Population, filename::String, runNumber::Int=-1)
    if self.currGeneration != self.maxGeneration
        println("You have to evolve population first!")
        return false
    end

    if !self.isTestRun || length(self.bestsVector) != self.maxGeneration
        println("You have to set isTestRun = true during population initialization!")
        return false
    end

    title = "mutProb: $(self.config.mutationProb), crossProb: $(self.config.crossoverProb), elite: $(self.config.eliteProc), popSize: $(self.config.populationSize), maxGen: $(self.maxGeneration)"
    if runNumber > 0
        title = "($runNumber)  " * title
    end
    xlabel = "Generation"
    ylabel = "Cost of best chromosom"

    ioff()
    fig = PyPlot.figure(title, figsize=(12, 12))
    ax = PyPlot.axes()
    plt = plot(1:self.maxGeneration, self.bestsVector)
    grid(true)
    PyPlot.xlabel(xlabel)
    PyPlot.ylabel(ylabel)
    PyPlot.title(title)
    # fig.canvas.draw()
    
    fig.savefig(filename)
    clf()
    close(fig)
    
    return true
end