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
    costFunction::Function
    bestsVector::Vector{Float64} # to plot results
    isTestRun::Bool
    mutex::ReentrantLock
    nDemand::Int
    nSupply::Int
    partialPopulationsData::Vector{Tuple{Int, Int, Int, Int}} # (firstIdx, lastIdx, parentsToPick, eliteCount)
end

function runGA(configFile::String, maxGeneration::Int, costFunctionName::String, isTestRun::Bool=false) 
    config = loadConfig(configFile)

    println("==================== CONFIG ====================")
    println("Population Size: ", config.populationSize, " Crossover: ", config.crossoverProb, " Mutation: ", config.mutationProb, " Elite: ", config.eliteProc, " Iterations: ", maxGeneration)
    println("Cost Func: ", costFunctionName)
    println("Test Run: ", isTestRun)
    println()


    functionsDict = getFunctions(config.costMatrix)
    costFunc = functionsDict[costFunctionName]

    population = nothing
    if config.mode == REGULAR_MODE
        population = initPopulation(config, maxGeneration, costFunc, isTestRun, 1)
    elseif config.mode == ISLAND_MODE
        population = initPopulation(config, maxGeneration, costFunc, isTestRun, Threads.nthreads())
    else
        error()
    end
    println("Best result in first generation: ", population.bestChromosom.cost)

    result = findSolution(population)
    
    if isTestRun
        drawResults(population, "resultPlot.png")
    end
    
    if !validate(result, config.demand, config.supply)
        error("Error while performing mutation.")
    end
    return result
end

"""
    initPopulation(config, maxGeneration, costFunction)

Initializes new population.

# Arguments
- `config::Config`: Config struct including all population's parameters.
- `maxGeneration::Integer`: number of iterations before algorithm stops.
- `costFunction::Function`: function used to calculate cost of single solution, should have signature func(resultMatrix::Array{Float64, 2}).
"""
function initPopulation(config::Config, maxGeneration::Int, costFunction::Function, isTestRun::Bool=false, numberOfSeparatePopulations::Int=1)
    validate!(config)

    chromosomSet = Vector{Chromosom}()
    mutex = ReentrantLock()
    Threads.@threads for i = 1 : config.populationSize
        c = init(config.demand, config.supply)
        eval!(c, costFunction)
        lock(mutex)
        push!(chromosomSet, c)
        unlock(mutex)
    end

    sort!(chromosomSet)
    bestChromosom = copy(chromosomSet[1])

    # to draw plots
    vec = Vector{Float64}()
    if isTestRun
        push!(vec, getCost(bestChromosom, costFunction))
    end

    nDemand, nSupply = getSizeForMutation(bestChromosom, config.mutationRate)

    partialPopulationsData = getPartialPopulationsData(config, numberOfSeparatePopulations)

    return Population(config, 1, maxGeneration, chromosomSet, bestChromosom, costFunction, vec, isTestRun, mutex, nDemand, nSupply, partialPopulationsData)
end

function getPartialPopulationsData(config::Config, numberOfSeparatePopulations::Int)
    size = floor(Int, config.populationSize / numberOfSeparatePopulations)
    
    firstIdx = Vector{Int}(undef, numberOfSeparatePopulations)
    firstIdx[1] = 1
    for i = 2 : length(firstIdx)
        firstIdx[i] = size + firstIdx[i-1]
    end

    idx = 2
    while firstIdx[numberOfSeparatePopulations] + size - 1 < config.populationSize
        for i = idx : numberOfSeparatePopulations
            firstIdx[i] += 1
        end
        idx += 1
    end

    lastIdx = Vector{Int}(undef, numberOfSeparatePopulations)
    lastIdx[numberOfSeparatePopulations] = config.populationSize
    for i = numberOfSeparatePopulations-1 : -1 : 1
        lastIdx[i] = firstIdx[i+1] - 1
    end

    parentsToPick = Vector{Int}(undef, numberOfSeparatePopulations)
    elites = Vector{Int}(undef, numberOfSeparatePopulations)

    allElites = floor(Int, config.populationSize * config.eliteProc)
    allParents = floor(Int, config.populationSize * config.crossoverProb)
    if allParents % 2 == 1
        allParents += 1
    end
    if allParents + allElites > config.populationSize
        allElites -= 1
    end

    parentsEach = floor(Int, allParents / numberOfSeparatePopulations)
    elitesEach = floor(Int, allElites / numberOfSeparatePopulations)
    for i = 1 : numberOfSeparatePopulations
        parentsToPick[i] = parentsEach
        elites[i] = elitesEach
    end

    idx = 1
    while sum(elites) != allElites
        elites[idx] += 1
        idx += 1
    end
    idx = 1
    while sum(parentsToPick) != allParents
        parentsToPick[idx] += 1
        idx += 1
    end

    for i = 1 : numberOfSeparatePopulations
        if parentsToPick[i] % 2 == 1
            if lastIdx[i] - firstIdx[i] + 1 - elites[i] > parentsToPick[i]
                parentsToPick[i] += 1
            else
                parentsToPick[i] -= 1
            end
        end
    end

    partialPopulationsData = Vector{Tuple{Int, Int, Int, Int}}()
    for i = 1 : numberOfSeparatePopulations
        push!(partialPopulationsData, (firstIdx[i], lastIdx[i], parentsToPick[i], elites[i]))
    end

    return partialPopulationsData
end

"""
    Select chromosoms to reproduction.
"""
function selection(self::Population, parentsToPick::Int)
    #1
    fittness = Vector{Float64}(undef, length(self.chromosomSet))
    
    fittness[length(self.chromosomSet)] = getCost(self.chromosomSet[length(self.chromosomSet)], self.costFunction)
    for i = length(self.chromosomSet)-1 : -1 : 1
        fittness[i] = getCost(self.chromosomSet[i], self.costFunction) + fittness[i+1]
    end

    #2
    fittness ./= fittness[1]

    #3
    parents = Vector{Chromosom}(undef, parentsToPick)

    # println(fittness)
    for i = 1 : parentsToPick
        pick = rand()
        # println(pick)
        idx = findfirst(x -> x <= pick, fittness)
        if idx === nothing
            idx = 1
        end
        parents[i] = copy(self.chromosomSet[idx])
    end

    return parents
end

function islandSelection(self::Population, firstIdx::Int, lastIdx::Int, parentsToPick::Int)
    #1
    currIdx = lastIdx - firstIdx + 1
    fittness = Vector{Float64}(undef, currIdx)
    
    fittness[currIdx] = getCost(self.chromosomSet[lastIdx], self.costFunction)
    for i = lastIdx-1 : -1 : firstIdx
        currIdx -= 1
        fittness[currIdx] = getCost(self.chromosomSet[i], self.costFunction) + fittness[currIdx+1]
    end

    #2
    fittness ./= fittness[1]

    #3
    parents = Vector{Chromosom}(undef, parentsToPick)

    for i = 1 : parentsToPick
        pick = rand()
        idx = findfirst(x -> x <= pick, fittness)
        if idx === nothing
            idx = 1
        end
        parents[i] = copy(self.chromosomSet[firstIdx + idx - 1])
    end

    return parents
end

"""
    nextGeneration!(self)

Performs single iteration of genetic algorithm.

# Arguments
- `self::Population`: evolving population.
"""
function nextGeneration!(self::Population, parentsToPick::Int, eliteCount::Int)
    parents = selection(self, parentsToPick)
    
    newChromosomeSet = Vector{Chromosom}(undef, length(self.chromosomSet))

    Threads.@threads for i = 1 : 2 : length(parents)
        cross!(parents[i], parents[i+1])
        newChromosomeSet[i] = parents[i]
        newChromosomeSet[i+1] = parents[i+1]
        for j = 0 : 1
            if rand() <= self.config.mutationProb
                if rand() <= 0.5
                    mutate2!(newChromosomeSet[i+j], self.config.demand, self.config.supply, self.nDemand, self.nSupply)
                else
                    mutate!(newChromosomeSet[i+j], self.config.demand, self.config.supply, self.nDemand, self.nSupply)
                end
            end
            eval!(newChromosomeSet[i+j], self.costFunction)
        end
    end

    Threads.@threads for i = length(parents) + 1 : self.config.populationSize
        if i - length(parents) <= eliteCount
            newChromosomeSet[i] = self.chromosomSet[i - length(parents)]
        else
            selected_idx = rand(eliteCount+1 : self.config.populationSize)
            newChromosomeSet[i] = copy(self.chromosomSet[selected_idx])
        end

        if rand() <= self.config.mutationProb
            if rand() <= 0.5
                mutate2!(newChromosomeSet[i], self.config.demand, self.config.supply, self.nDemand, self.nSupply)
            else
                mutate!(newChromosomeSet[i], self.config.demand, self.config.supply, self.nDemand, self.nSupply)
            end
        end
        eval!(newChromosomeSet[i], self.costFunction)
    end

    sort!(newChromosomeSet)
    self.chromosomSet = newChromosomeSet
    
    if getCost(self.bestChromosom, self.costFunction) > getCost(self.chromosomSet[1], self.costFunction)
        self.bestChromosom = copy(self.chromosomSet[1])
    end

    self.currGeneration += 1
    return nothing
end

function islandNextGeneration!(self::Population, firstIdx::Int, lastIdx::Int, parentsToPick::Int, eliteCount::Int, newChromosomeSet::Vector{Chromosom})
    parents = islandSelection(self, firstIdx, lastIdx, parentsToPick)
    
    currIdx = firstIdx
    for i = 1 : eliteCount
        newChromosomeSet[currIdx] = self.chromosomSet[currIdx]
        currIdx += 1
    end

    for i = 1 : 2 : length(parents)
        cross!(parents[i], parents[i+1])
        newChromosomeSet[currIdx] = parents[i]
        newChromosomeSet[currIdx+1] = parents[i+1]
        currIdx += 2
    end

    for i = currIdx : lastIdx
        selected_idx = rand(0 : lastIdx - firstIdx)
        newChromosomeSet[i] = copy(self.chromosomSet[firstIdx + selected_idx])
    end

    for i = firstIdx : lastIdx
        if rand() <= self.config.mutationProb
            if rand() <= 0.5
                mutate2!(newChromosomeSet[i], self.config.demand, self.config.supply, self.nDemand, self.nSupply)
            else
                mutate!(newChromosomeSet[i], self.config.demand, self.config.supply, self.nDemand, self.nSupply)
            end
        end
        eval!(newChromosomeSet[i], self.costFunction)
    end

    sort!(newChromosomeSet, firstIdx, lastIdx, QuickSort, Base.Order.Forward)
    
    for i = firstIdx : lastIdx
        self.chromosomSet[i] = newChromosomeSet[i]
    end
    
    return nothing
end

function nextGenerationTest!(self::Population, parentsToPick::Int, eliteCount::Int)
    nextGeneration!(self, parentsToPick, eliteCount)
    push!(self.bestsVector, getCost(self.chromosomSet[1], self.costFunction))
    if self.currGeneration % 1000 == 0
        println("Generation: ", self.currGeneration)
    end

    return nothing
end

"""
    Run's genetic algorithm on population.
"""
function findSolution(population::Population)
    if population.isTestRun
        if population.config.mode == REGULAR_MODE
            # TEST - REGULAR MODE
            while population.currGeneration < population.maxGeneration
                nextGenerationTest!(population, population.partialPopulationsData[1][3], population.partialPopulationsData[1][4])
            end
        elseif population.config.mode == ISLAND_MODE
            # TEST - ISLAND MODE
            newChromosomeSet = Vector{Chromosom}(undef, population.config.populationSize)
            while population.currGeneration < population.maxGeneration
                shuffle!(population.chromosomSet)
                
                Threads.@threads for i = 1 : length(population.partialPopulationsData)
                    sort!(population.chromosomSet, population.partialPopulationsData[i][1], population.partialPopulationsData[i][2], QuickSort, Base.Order.Forward)
                    for j = 1 : population.config.numberOfSeparateGenerations
                        islandNextGeneration!(population, population.partialPopulationsData[i]..., newChromosomeSet)
                    end
                end
                population.currGeneration += population.config.numberOfSeparateGenerations

                sort!(population.chromosomSet)
                population.bestChromosom = copy(population.chromosomSet[1])
                push!(population.bestsVector, getCost(population.chromosomSet[1], population.costFunction))
            end
        end
    else
        if population.config.mode == REGULAR_MODE
            # REGULAR MODE
            while population.currGeneration < population.maxGeneration
                nextGeneration!(population, population.partialPopulationsData[1][3], population.partialPopulationsData[1][4])
            end
        elseif population.config.mode == ISLAND_MODE
            # ISLAND MODE
            newChromosomeSet = Vector{Chromosom}(undef, population.config.populationSize)
            while population.currGeneration < population.maxGeneration
                shuffle!(population.chromosomSet)
                
                Threads.@threads for i = 1 : length(population.partialPopulationsData)
                    sort!(population.chromosomSet, population.partialPopulationsData[i][1], population.partialPopulationsData[i][2], QuickSort, Base.Order.Forward)
                    for j = 1 : population.config.numberOfSeparateGenerations
                        islandNextGeneration!(population, population.partialPopulationsData[i]..., newChromosomeSet)
                    end
                end
                population.currGeneration += population.config.numberOfSeparateGenerations

                sort!(population.chromosomSet)
                population.bestChromosom = copy(population.chromosomSet[1])
            end
        end
    end

    return population.bestChromosom
end

function drawResults(self::Population, filename::String, runNumber::Int=-1)
    if self.currGeneration < self.maxGeneration
        println("You have to evolve population first!")
        return false
    end

    # if !self.isTestRun || length(self.bestsVector) != self.maxGeneration
    #     println("You have to set isTestRun = true during population initialization!")
    #     return false
    # end

    title = "mutProb: $(self.config.mutationProb), crossProb: $(self.config.crossoverProb), elite: $(self.config.eliteProc), popSize: $(self.config.populationSize), maxGen: $(self.maxGeneration)"
    if runNumber > 0
        title = "($runNumber)  " * title
    end
    xlabel = "Generation"
    ylabel = "Cost of best chromosom"

    ioff()
    fig = PyPlot.figure(title, figsize=(12, 12))
    ax = PyPlot.axes()
    plt = plot(1 : self.config.numberOfSeparateGenerations : self.currGeneration, self.bestsVector)
    grid(true)
    PyPlot.xlabel(xlabel)
    PyPlot.ylabel(ylabel)
    PyPlot.title(title)

    fig.savefig(filename)
    clf()
    close(fig)
    
    return true
end